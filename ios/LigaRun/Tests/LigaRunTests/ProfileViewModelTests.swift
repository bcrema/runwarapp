import CoreLocation
import XCTest
@testable import LigaRun

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
            runService: ProfileRunServiceStub(runsResult: .success([])),
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
            runService: ProfileRunServiceStub(runsResult: .success(allRuns)),
            historyLimit: 2
        )

        await viewModel.loadRecentRuns()

        XCTAssertEqual(viewModel.recentRuns.map(\.id), ["run-1", "run-2"])
        XCTAssertEqual(viewModel.historyState, .loaded)
    }

    @MainActor
    func testLoadRecentRunsSetsFailedStateForApiError() async {
        let viewModel = ProfileViewModel(
            session: SessionStore(),
            runService: ProfileRunServiceStub(runsResult: .failure(APIError(error: "INTERNAL_ERROR", message: "Boom", details: nil)))
        )

        await viewModel.loadRecentRuns()

        XCTAssertTrue(viewModel.recentRuns.isEmpty)
        XCTAssertEqual(viewModel.historyState, .failed("Boom"))
    }

    @MainActor
    func testLoadRecentRunsSetsFailedStateForGenericError() async {
        let viewModel = ProfileViewModel(
            session: SessionStore(),
            runService: ProfileRunServiceStub(
                runsResult: .failure(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Offline"]))
            )
        )

        await viewModel.loadRecentRuns()

        XCTAssertTrue(viewModel.recentRuns.isEmpty)
        XCTAssertEqual(viewModel.historyState, .failed("Offline"))
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
            targetQuadraId: "quadra-1",
            isValidForTerritory: true,
            fraudFlags: [],
            createdAt: dateString
        )
    }
}

private final class ProfileRunServiceStub: RunServiceProtocol {
    let runsResult: Result<[Run], Error>
    let dailyStatusResult: Result<DailyStatus, Error>

    init(
        runsResult: Result<[Run], Error> = .success([]),
        dailyStatusResult: Result<DailyStatus, Error> = .success(
            DailyStatus(userActionsUsed: 0, userActionsRemaining: 1, bandeiraActionsUsed: nil, bandeiraActionCap: nil)
        )
    ) {
        self.runsResult = runsResult
        self.dailyStatusResult = dailyStatusResult
    }

    func submitRunGpx(fileURL: URL) async throws -> RunSubmissionResult {
        fatalError("submitRunGpx is not implemented for ProfileRunServiceStub")
    }

    func submitRunCoordinates(coordinates: [CLLocationCoordinate2D], timestamps: [Int]) async throws -> RunSubmissionResult {
        fatalError("submitRunCoordinates is not implemented for ProfileRunServiceStub")
    }

    func getMyRuns() async throws -> [Run] {
        try runsResult.get()
    }

    func getDailyStatus() async throws -> DailyStatus {
        try dailyStatusResult.get()
    }
}
