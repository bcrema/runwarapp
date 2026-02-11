import CoreLocation
import XCTest
@testable import LigaRun

final class RunSyncCoordinatorTests: XCTestCase {
    @MainActor
    func testFinishRunTransitionsToCompleted() async {
        let expectedResult = makeRunSubmissionResultFixture(runId: "run-sync-success")
        let uploadService = RunUploadServiceStub(outcomes: [.success(expectedResult)])
        let coordinator = RunSyncCoordinator(
            runSessionStore: RunSessionStore(fileURL: temporaryStoreURL()),
            uploadService: uploadService,
            timeout: 1
        )

        var transitions: [CompanionSyncState] = []
        coordinator.onStateChange = { transitions.append($0) }

        await coordinator.finishRun(
            startedAt: Date().addingTimeInterval(-600),
            endedAt: Date(),
            duration: 600,
            distanceMeters: 1500,
            locations: makeLocations()
        )

        XCTAssertTrue(containsState(transitions, matching: .waitingForSync))
        XCTAssertTrue(containsState(transitions, matching: .uploading))
        XCTAssertTrue(containsState(transitions, matching: .completed(expectedResult)))
        let uploadCalls = await uploadService.recordedUploadCalls()
        XCTAssertEqual(uploadCalls, 1)
    }

    @MainActor
    func testFailureTransitionsToErrorAndRetryRecovers() async {
        let expectedResult = makeRunSubmissionResultFixture(runId: "run-sync-retry")
        let uploadService = RunUploadServiceStub(
            outcomes: [
                .failure(APIError(error: "INTERNAL_ERROR", message: "Boom", details: nil)),
                .success(expectedResult)
            ]
        )
        let coordinator = RunSyncCoordinator(
            runSessionStore: RunSessionStore(fileURL: temporaryStoreURL()),
            uploadService: uploadService,
            timeout: 1
        )

        await coordinator.finishRun(
            startedAt: Date().addingTimeInterval(-300),
            endedAt: Date(),
            duration: 300,
            distanceMeters: 1300,
            locations: makeLocations()
        )

        guard case .failed(let message) = coordinator.state else {
            return XCTFail("Expected failed state after first upload")
        }
        XCTAssertEqual(message, "Boom")

        await coordinator.retry()

        guard case .completed(let result) = coordinator.state else {
            return XCTFail("Expected completed state after retry")
        }
        XCTAssertEqual(result.run.id, "run-sync-retry")
        let uploadCalls = await uploadService.recordedUploadCalls()
        XCTAssertEqual(uploadCalls, 2)
    }

    @MainActor
    func testTimeoutTransitionsToFailedState() async {
        let expectedResult = makeRunSubmissionResultFixture(runId: "run-timeout")
        let uploadService = RunUploadServiceStub(outcomes: [.delayedSuccess(0.2, expectedResult)])
        let coordinator = RunSyncCoordinator(
            runSessionStore: RunSessionStore(fileURL: temporaryStoreURL()),
            uploadService: uploadService,
            timeout: 0.01
        )

        await coordinator.finishRun(
            startedAt: Date().addingTimeInterval(-200),
            endedAt: Date(),
            duration: 200,
            distanceMeters: 1200,
            locations: makeLocations()
        )

        guard case .failed(let message) = coordinator.state else {
            return XCTFail("Expected failed state for timeout")
        }
        XCTAssertEqual(message, "Sincronizacao demorou mais que o esperado.")
    }

    private func containsState(_ states: [CompanionSyncState], matching expected: CompanionSyncState) -> Bool {
        states.contains { candidate in
            switch (candidate, expected) {
            case (.running, .running), (.waitingForSync, .waitingForSync), (.uploading, .uploading):
                return true
            case (.completed(let lhs), .completed(let rhs)):
                return lhs.run.id == rhs.run.id
            case (.failed(let lhs), .failed(let rhs)):
                return lhs == rhs
            default:
                return false
            }
        }
    }

    private func makeLocations() -> [CLLocation] {
        [
            CLLocation(latitude: -25.4295, longitude: -49.2717),
            CLLocation(latitude: -25.4285, longitude: -49.2717)
        ]
    }

    private func temporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("run-sync-\(UUID().uuidString).json")
    }
}

private enum UploadOutcome {
    case success(RunSubmissionResult)
    case delayedSuccess(TimeInterval, RunSubmissionResult)
    case failure(Error)
}

private actor RunUploadServiceStub: RunUploadServiceProtocol {
    private var outcomes: [UploadOutcome]
    private var uploadCalls = 0

    init(outcomes: [UploadOutcome]) {
        self.outcomes = outcomes
    }

    func uploadPendingSessions() async -> [RunSubmissionResult] {
        []
    }

    func upload(_ session: RunSessionRecord) async throws -> RunSubmissionResult {
        uploadCalls += 1
        guard !outcomes.isEmpty else {
            throw APIError(error: "INTERNAL_ERROR", message: "Missing test outcome", details: nil)
        }

        let outcome = outcomes.removeFirst()
        switch outcome {
        case .success(let result):
            return result
        case .delayedSuccess(let seconds, let result):
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return result
        case .failure(let error):
            throw error
        }
    }

    func recordedUploadCalls() -> Int {
        uploadCalls
    }
}
