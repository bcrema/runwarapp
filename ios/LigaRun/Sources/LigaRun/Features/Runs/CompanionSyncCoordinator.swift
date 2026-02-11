import Foundation
import CoreLocation

enum CompanionSyncState {
    case running
    case waitingForSync
    case uploading
    case completed(RunSubmissionResult)
    case failed(message: String)

    var isTerminal: Bool {
        switch self {
        case .completed, .failed:
            return true
        default:
            return false
        }
    }
}

enum CompanionSyncEvent {
    case runStarted
    case runStopped
    case uploadStarted
    case uploadSucceeded(RunSubmissionResult)
    case uploadFailed(String)
    case retryRequested
    case reset
}

extension CompanionSyncState {
    func transitioning(on event: CompanionSyncEvent) -> CompanionSyncState {
        switch (self, event) {
        case (_, .reset), (_, .runStarted):
            return .running
        case (.running, .runStopped):
            return .waitingForSync
        case (.failed, .retryRequested):
            return .waitingForSync
        case (.waitingForSync, .uploadStarted):
            return .uploading
        case (.uploading, .uploadSucceeded(let result)):
            return .completed(result)
        case (.uploading, .uploadFailed(let message)):
            return .failed(message: message)
        case (.waitingForSync, .uploadFailed(let message)):
            return .failed(message: message)
        default:
            return self
        }
    }
}

@MainActor
protocol RunSyncCoordinating: AnyObject {
    var state: CompanionSyncState { get }
    var onStateChange: ((CompanionSyncState) -> Void)? { get set }

    func finishRun(
        startedAt: Date,
        endedAt: Date,
        duration: TimeInterval,
        distanceMeters: Double,
        locations: [CLLocation]
    ) async
    func retry() async
    func cancel()
}

enum RunSyncCoordinatorError: LocalizedError {
    case timeout

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Sincronizacao demorou mais que o esperado."
        }
    }
}

@MainActor
final class RunSyncCoordinator: RunSyncCoordinating {
    private(set) var state: CompanionSyncState = .running {
        didSet { onStateChange?(state) }
    }
    var onStateChange: ((CompanionSyncState) -> Void)?

    private let runSessionStore: RunSessionStore
    private let uploadService: RunUploadServiceProtocol
    private let timeout: TimeInterval
    private var pendingSession: RunSessionRecord?
    private var uploadTask: Task<Void, Never>?

    init(
        runSessionStore: RunSessionStore,
        uploadService: RunUploadServiceProtocol,
        timeout: TimeInterval = 20
    ) {
        self.runSessionStore = runSessionStore
        self.uploadService = uploadService
        self.timeout = timeout
    }

    func finishRun(
        startedAt: Date,
        endedAt: Date,
        duration: TimeInterval,
        distanceMeters: Double,
        locations: [CLLocation]
    ) async {
        cancelCurrentTask()
        transition(.runStopped)

        let session = RunSessionRecord(
            id: UUID(),
            startedAt: startedAt,
            endedAt: endedAt,
            duration: duration,
            distanceMeters: distanceMeters,
            points: locations.map(RunTrackPoint.init(location:)),
            status: .pending,
            lastUploadAttempt: nil,
            lastError: nil
        )
        pendingSession = session
        await runUploadPipeline(session: session, shouldPersist: true)
    }

    func retry() async {
        guard let session = pendingSession else { return }
        cancelCurrentTask()
        transition(.retryRequested)
        await runUploadPipeline(session: session, shouldPersist: false)
    }

    func cancel() {
        cancelCurrentTask()
        if case .uploading = state {
            transition(.uploadFailed("Sincronizacao cancelada. Tente novamente."))
        }
    }

    private func cancelCurrentTask() {
        uploadTask?.cancel()
        uploadTask = nil
    }

    private func runUploadPipeline(session: RunSessionRecord, shouldPersist: Bool) async {
        transition(.uploadStarted)

        uploadTask = Task { [weak self] in
            guard let self else { return }
            do {
                if shouldPersist {
                    _ = try await runSessionStore.append(session)
                }

                let result = try await uploadWithTimeout(session)
                pendingSession = nil
                transition(.uploadSucceeded(result))
            } catch {
                transition(.uploadFailed(syncErrorMessage(from: error)))
            }
        }

        await uploadTask?.value
        uploadTask = nil
    }

    private func uploadWithTimeout(_ session: RunSessionRecord) async throws -> RunSubmissionResult {
        try await withThrowingTaskGroup(of: RunSubmissionResult.self) { group in
            group.addTask { [uploadService] in
                try await uploadService.upload(session)
            }
            group.addTask { [timeout] in
                let nanos = UInt64(timeout * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanos)
                throw RunSyncCoordinatorError.timeout
            }

            guard let firstFinished = try await group.next() else {
                throw RunSyncCoordinatorError.timeout
            }
            group.cancelAll()
            return firstFinished
        }
    }

    private func transition(_ event: CompanionSyncEvent) {
        state = state.transitioning(on: event)
    }

    private func syncErrorMessage(from error: Error) -> String {
        if error is CancellationError {
            return "Sincronizacao cancelada. Tente novamente."
        }
        if let syncError = error as? RunSyncCoordinatorError {
            return syncError.localizedDescription
        }
        if let apiError = error as? APIError {
            return apiError.message
        }
        return "Falha ao sincronizar corrida. Tente novamente."
    }
}
