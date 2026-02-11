import XCTest
@testable import LigaRun

final class CompanionSyncStateTests: XCTestCase {
    func testStateTransitionsFollowDeterministicFlow() {
        var state: CompanionSyncState = .running

        state = state.transitioning(on: .runStopped)
        assertState(state, matches: .waitingForSync)

        state = state.transitioning(on: .uploadStarted)
        assertState(state, matches: .uploading)

        state = state.transitioning(on: .uploadFailed("Falha"))
        assertState(state, matches: .failed(message: "Falha"))

        state = state.transitioning(on: .retryRequested)
        assertState(state, matches: .waitingForSync)

        state = state.transitioning(on: .uploadStarted)
        assertState(state, matches: .uploading)

        let result = makeRunSubmissionResultFixture(runId: "run-final")
        state = state.transitioning(on: .uploadSucceeded(result))
        switch state {
        case .completed(let completedResult):
            XCTAssertEqual(completedResult.run.id, "run-final")
        default:
            XCTFail("Expected completed state")
        }
    }

    func testInvalidTransitionKeepsCurrentState() {
        let initial: CompanionSyncState = .running
        let next = initial.transitioning(on: .uploadStarted)
        assertState(next, matches: .running)
    }

    private func assertState(_ lhs: CompanionSyncState, matches rhs: CompanionSyncState) {
        switch (lhs, rhs) {
        case (.running, .running), (.waitingForSync, .waitingForSync), (.uploading, .uploading):
            return
        case (.completed(let lhsResult), .completed(let rhsResult)):
            XCTAssertEqual(lhsResult.run.id, rhsResult.run.id)
        case (.failed(let lhsMessage), .failed(let rhsMessage)):
            XCTAssertEqual(lhsMessage, rhsMessage)
        default:
            XCTFail("State mismatch: \(lhs) vs \(rhs)")
        }
    }
}
