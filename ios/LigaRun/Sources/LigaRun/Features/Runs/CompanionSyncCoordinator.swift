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
    func reset()

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

private actor FirstUploadResultResolver {
    private var continuation: CheckedContinuation<RunSubmissionResult, Error>?

    init(_ continuation: CheckedContinuation<RunSubmissionResult, Error>) {
        self.continuation = continuation
    }

    func resumeIfNeeded(with result: Result<RunSubmissionResult, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
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

    func reset() {
        cancelCurrentTask()
        pendingSession = nil
        transition(.reset)
    }

    func finishRun(
        startedAt: Date,
        endedAt: Date,
        duration: TimeInterval,
        distanceMeters: Double,
        locations: [CLLocation]
    ) async {
        cancelCurrentTask()
        transition(.reset)
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
        let nanos = UInt64(timeout * 1_000_000_000)
        var uploadTask: Task<Void, Never>?
        var timeoutTask: Task<Void, Never>?

        let result = try await withCheckedThrowingContinuation { continuation in
            let resolver = FirstUploadResultResolver(continuation)

            uploadTask = Task { @MainActor [uploadService] in
                do {
                    let uploadResult = try await uploadService.upload(session)
                    await resolver.resumeIfNeeded(with: .success(uploadResult))
                } catch {
                    await resolver.resumeIfNeeded(with: .failure(error))
                }
            }

            timeoutTask = Task { [nanos] in
                do {
                    try await Task.sleep(nanoseconds: nanos)
                    await resolver.resumeIfNeeded(with: .failure(RunSyncCoordinatorError.timeout))
                } catch {
                    // Task was cancelled after upload finished first.
                }
            }
        }

        uploadTask?.cancel()
        timeoutTask?.cancel()
        return result
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
