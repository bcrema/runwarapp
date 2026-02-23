import CoreLocation
import XCTest
@testable import LigaRun

final class CompanionRunManagerTests: XCTestCase {
    @MainActor
    func testStartPauseResumeStopTransitionsAndTrackingCalls() async {
        let locationManager = LocationManagerSpy()
        let syncCoordinator = RunSyncCoordinatorSpy()
        let runManager = CompanionRunManager(locationManager: locationManager, syncCoordinator: syncCoordinator)

        runManager.startIfNeeded()
        XCTAssertTrue(isState(runManager.state, .running))
        XCTAssertEqual(locationManager.requestPermissionCalls, 1)
        XCTAssertEqual(locationManager.startTrackingCalls, 1)
        XCTAssertEqual(syncCoordinator.resetCalls, 1)

        runManager.pause()
        XCTAssertTrue(isState(runManager.state, .paused))
        XCTAssertEqual(locationManager.stopTrackingCalls, 1)

        runManager.resume()
        XCTAssertTrue(isState(runManager.state, .running))
        XCTAssertEqual(locationManager.startTrackingCalls, 2)

        runManager.stop()
        XCTAssertTrue(isState(runManager.state, .idle))
        XCTAssertEqual(locationManager.stopTrackingCalls, 2)
        await Task.yield()
        XCTAssertEqual(syncCoordinator.finishRunCalls, 1)
    }


    @MainActor
    func testStopAndSyncForwardsCompetitionContextToCoordinator() async {
        let locationManager = LocationManagerSpy()
        let syncCoordinator = RunSyncCoordinatorSpy()
        let runManager = CompanionRunManager(locationManager: locationManager, syncCoordinator: syncCoordinator)

        runManager.start()
        runManager.stopAndSync(competitionMode: .competitive, targetQuadraId: "quadra-ctx", eligibilityReason: nil)
        await Task.yield()

        XCTAssertEqual(syncCoordinator.finishRunCalls, 1)
        XCTAssertEqual(syncCoordinator.lastCompetitionMode, .competitive)
        XCTAssertEqual(syncCoordinator.lastTargetQuadraId, "quadra-ctx")
        XCTAssertNil(syncCoordinator.lastEligibilityReason)
    }

    @MainActor
    func testStartIfNeededDoesNotRestartWhenAlreadyRunning() {
        let locationManager = LocationManagerSpy()
        let syncCoordinator = RunSyncCoordinatorSpy()
        let runManager = CompanionRunManager(locationManager: locationManager, syncCoordinator: syncCoordinator)

        runManager.startIfNeeded()
        runManager.startIfNeeded()

        XCTAssertEqual(locationManager.startTrackingCalls, 1)
        XCTAssertEqual(locationManager.requestPermissionCalls, 1)
    }

    @MainActor
    func testReceivingLocationsUpdatesDistanceAndProgress() async {
        let locationManager = LocationManagerSpy()
        let syncCoordinator = RunSyncCoordinatorSpy()
        let runManager = CompanionRunManager(locationManager: locationManager, syncCoordinator: syncCoordinator)

        runManager.start()
        locationManager.emit(CLLocation(latitude: -25.4295, longitude: -49.2717))
        locationManager.emit(CLLocation(latitude: -25.4285, longitude: -49.2717))
        await Task.yield()

        XCTAssertEqual(runManager.locations.count, 2)
        XCTAssertGreaterThan(runManager.distanceMeters, 0)
        XCTAssertGreaterThan(runManager.loopProgress, 0)
    }

    @MainActor
    func testRetrySyncDelegatesToCoordinator() async {
        let locationManager = LocationManagerSpy()
        let syncCoordinator = RunSyncCoordinatorSpy()
        let runManager = CompanionRunManager(locationManager: locationManager, syncCoordinator: syncCoordinator)

        runManager.retrySync()
        await Task.yield()

        XCTAssertEqual(syncCoordinator.retryCalls, 1)
    }

    @MainActor
    func testCompletedSyncPublishesSubmissionResult() {
        let locationManager = LocationManagerSpy()
        let syncCoordinator = RunSyncCoordinatorSpy()
        let runManager = CompanionRunManager(locationManager: locationManager, syncCoordinator: syncCoordinator)
        let result = makeRunSubmissionResultFixture(runId: "run-completed")

        syncCoordinator.emit(state: .completed(result))

        XCTAssertEqual(runManager.submissionResult?.run.id, "run-completed")
    }

    private func isState(_ lhs: RunState, _ rhs: RunState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.running, .running), (.paused, .paused):
            return true
        default:
            return false
        }
    }
}

private final class LocationManagerSpy: LocationManager {
    private(set) var requestPermissionCalls = 0
    private(set) var startTrackingCalls = 0
    private(set) var stopTrackingCalls = 0

    override func requestPermission() {
        requestPermissionCalls += 1
    }

    override func startTracking() {
        startTrackingCalls += 1
    }

    override func stopTracking() {
        stopTrackingCalls += 1
    }

    func emit(_ location: CLLocation) {
        self.location = location
    }
}

@MainActor
private final class RunSyncCoordinatorSpy: RunSyncCoordinating {
    var state: CompanionSyncState = .running
    var onStateChange: ((CompanionSyncState) -> Void)?

    private(set) var finishRunCalls = 0
    private(set) var lastCompetitionMode: RunCompetitionMode?
    private(set) var lastTargetQuadraId: String?
    private(set) var lastEligibilityReason: String?
    private(set) var retryCalls = 0
    private(set) var resetCalls = 0

    func reset() {
        resetCalls += 1
        state = .running
        onStateChange?(state)
    }

    func finishRun(
        startedAt: Date,
        endedAt: Date,
        duration: TimeInterval,
        distanceMeters: Double,
        locations: [CLLocation],
        competitionMode: RunCompetitionMode,
        targetQuadraId: String?,
        eligibilityReason: String?
    ) async {
        finishRunCalls += 1
        lastCompetitionMode = competitionMode
        lastTargetQuadraId = targetQuadraId
        lastEligibilityReason = eligibilityReason
    }

    func retry() async {
        retryCalls += 1
    }

    func cancel() {}

    func emit(state: CompanionSyncState) {
        self.state = state
        onStateChange?(state)
    }
}
