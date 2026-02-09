import CoreLocation
import XCTest
@testable import LigaRun

final class CompanionRunManagerTests: XCTestCase {
    @MainActor
    func testStartPauseResumeStopTransitionsAndTrackingCalls() async {
        let locationManager = LocationManagerSpy()
        let runManager = CompanionRunManager(locationManager: locationManager)

        runManager.startIfNeeded()
        XCTAssertTrue(isState(runManager.state, .running))
        XCTAssertEqual(locationManager.requestPermissionCalls, 1)
        XCTAssertEqual(locationManager.startTrackingCalls, 1)

        runManager.pause()
        XCTAssertTrue(isState(runManager.state, .paused))
        XCTAssertEqual(locationManager.stopTrackingCalls, 1)

        runManager.resume()
        XCTAssertTrue(isState(runManager.state, .running))
        XCTAssertEqual(locationManager.startTrackingCalls, 2)

        runManager.stop()
        XCTAssertTrue(isState(runManager.state, .idle))
        XCTAssertEqual(locationManager.stopTrackingCalls, 2)
    }

    @MainActor
    func testStartIfNeededDoesNotRestartWhenAlreadyRunning() {
        let locationManager = LocationManagerSpy()
        let runManager = CompanionRunManager(locationManager: locationManager)

        runManager.startIfNeeded()
        runManager.startIfNeeded()

        XCTAssertEqual(locationManager.startTrackingCalls, 1)
        XCTAssertEqual(locationManager.requestPermissionCalls, 1)
    }

    @MainActor
    func testReceivingLocationsUpdatesDistanceAndProgress() async {
        let locationManager = LocationManagerSpy()
        let runManager = CompanionRunManager(locationManager: locationManager)

        runManager.start()
        locationManager.emit(CLLocation(latitude: -25.4295, longitude: -49.2717))
        locationManager.emit(CLLocation(latitude: -25.4285, longitude: -49.2717))
        await Task.yield()

        XCTAssertEqual(runManager.locations.count, 2)
        XCTAssertGreaterThan(runManager.distanceMeters, 0)
        XCTAssertGreaterThan(runManager.loopProgress, 0)
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
