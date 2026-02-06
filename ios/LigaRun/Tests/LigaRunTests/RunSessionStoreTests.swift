import XCTest
import CoreLocation
@testable import LigaRun

final class RunSessionStoreTests: XCTestCase {
    func testAppendAndLoadPersistsSession() async throws {
        let fileURL = makeTempFileURL()
        let store = RunSessionStore(fileURL: fileURL)
        let session = RunSessionRecord(
            id: UUID(),
            startedAt: Date(),
            endedAt: Date(),
            duration: 120,
            distanceMeters: 1000,
            points: [RunTrackPoint(location: CLLocation(latitude: 1, longitude: 2))],
            status: .pending,
            lastUploadAttempt: nil,
            lastError: nil
        )

        _ = try await store.append(session)
        let loaded = await store.loadSessions()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first, session)
    }

    func testUpdateReplacesExistingSession() async throws {
        let fileURL = makeTempFileURL()
        let store = RunSessionStore(fileURL: fileURL)
        let sessionId = UUID()
        let initial = RunSessionRecord(
            id: sessionId,
            startedAt: Date(),
            endedAt: Date(),
            duration: 100,
            distanceMeters: 500,
            points: [],
            status: .pending,
            lastUploadAttempt: nil,
            lastError: nil
        )

        _ = try await store.append(initial)

        var updated = initial
        updated.status = .uploaded
        _ = try await store.update(updated)

        let loaded = await store.loadSessions()
        XCTAssertEqual(loaded.first?.status, .uploaded)
    }

    func testRemoveDeletesSession() async throws {
        let fileURL = makeTempFileURL()
        let store = RunSessionStore(fileURL: fileURL)
        let sessionId = UUID()
        let session = RunSessionRecord(
            id: sessionId,
            startedAt: Date(),
            endedAt: Date(),
            duration: 60,
            distanceMeters: 300,
            points: [],
            status: .pending,
            lastUploadAttempt: nil,
            lastError: nil
        )

        _ = try await store.append(session)
        _ = try await store.remove(id: sessionId)

        let loaded = await store.loadSessions()
        XCTAssertTrue(loaded.isEmpty)
    }

    private func makeTempFileURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            XCTFail("Failed to create temporary directory: \(error)")
        }

        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory.appendingPathComponent("run-sessions.json")
    }
}

final class ProfileViewModelTests: XCTestCase {
    @MainActor
    func testStatsCompositionWithNilUserReturnsZeroedValues() {
        let viewModel = ProfileViewModel(session: SessionStore(), runService: ProfileRunServiceStub())

        let stats = viewModel.stats(for: nil)

        XCTAssertEqual(stats.totalRuns, 0)
        XCTAssertEqual(stats.totalDistance, 0)
        XCTAssertEqual(stats.totalTilesConquered, 0)
    }

    @MainActor
    func testStatsCompositionWithValidUserReturnsUserTotals() {
        let viewModel = ProfileViewModel(session: SessionStore(), runService: ProfileRunServiceStub())
        let user = User(
            id: "user-1",
            email: "runner@ligarun.app",
            username: "runner",
            avatarUrl: nil,
            isPublic: true,
            bandeiraId: nil,
            bandeiraName: nil,
            role: "USER",
            totalRuns: 12,
            totalDistance: 73.5,
            totalTilesConquered: 9
        )

        let stats = viewModel.stats(for: user)

        XCTAssertEqual(stats.totalRuns, 12)
        XCTAssertEqual(stats.totalDistance, 73.5)
        XCTAssertEqual(stats.totalTilesConquered, 9)
    }

    @MainActor
    func testLoadRecentRunsRendersEmptyHistoryStateWhenNoRunsExist() async {
        let viewModel = ProfileViewModel(
            session: SessionStore(),
            runService: ProfileRunServiceStub(runs: []),
            historyLimit: 10
        )

        await viewModel.loadRecentRuns()

        XCTAssertTrue(viewModel.recentRuns.isEmpty)
        XCTAssertEqual(viewModel.historyState, .empty)
    }

    @MainActor
    func testLoadRecentRunsLimitsHistoryToConfiguredSize() async {
        let allRuns = [makeRun(id: "run-1"), makeRun(id: "run-2"), makeRun(id: "run-3")]
        let viewModel = ProfileViewModel(
            session: SessionStore(),
            runService: ProfileRunServiceStub(runs: allRuns),
            historyLimit: 2
        )

        await viewModel.loadRecentRuns()

        XCTAssertEqual(viewModel.recentRuns.map(\.id), ["run-1", "run-2"])
        XCTAssertEqual(viewModel.historyState, .loaded)
    }

    private func makeRun(id: String) -> Run {
        let formatter = ISO8601DateFormatter()
        let date = Date()
        let dateString = formatter.string(from: date)
        return Run(
            id: id,
            userId: "user-1",
            distance: 5.42,
            duration: 1820,
            startTime: dateString,
            endTime: dateString,
            isLoopValid: true,
            loopDistance: 5400,
            territoryAction: "CONQUEST",
            targetTileId: "tile-1",
            isValidForTerritory: true,
            fraudFlags: [],
            createdAt: dateString
        )
    }
}

private struct ProfileRunServiceStub: RunServiceProtocol {
    var runs: [Run] = []
    var runsError: APIError? = nil

    func submitRunGpx(fileURL: URL) async throws -> RunSubmissionResult {
        fatalError("submitRunGpx is not implemented for ProfileRunServiceStub")
    }

    func submitRunCoordinates(coordinates: [CLLocationCoordinate2D], timestamps: [Int]) async throws -> RunSubmissionResult {
        fatalError("submitRunCoordinates is not implemented for ProfileRunServiceStub")
    }

    func getMyRuns() async throws -> [Run] {
        if let runsError {
            throw runsError
        }
        return runs
    }

    func getDailyStatus() async throws -> DailyStatus {
        DailyStatus(userActionsUsed: 0, userActionsRemaining: 1, bandeiraActionsUsed: nil, bandeiraActionCap: nil)
    }
}
