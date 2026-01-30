import CoreLocation
import XCTest
@testable import LigaRun

final class RunsViewModelTests: XCTestCase {
    @MainActor
    func testLoadKeepsRunsWhenDailyStatusFails() async {
        let run = makeRun()
        let service = RunServiceStub(
            runsResult: .success([run]),
            dailyStatusResult: .failure(APIError(error: "INTERNAL_ERROR", message: "Boom", details: nil))
        )
        let uploadStub = RunUploadServiceStub(results: [])
        let viewModel = RunsViewModel(session: SessionStore(), runService: service, uploadService: uploadStub)

        await viewModel.load()

        XCTAssertEqual(viewModel.runs.count, 1)
        XCTAssertEqual(viewModel.runs.first?.id, run.id)
        XCTAssertNil(viewModel.dailyStatus)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testLoadShowsApiErrorWhenRunsFail() async {
        let service = RunServiceStub(
            runsResult: .failure(APIError(error: "UNAUTHORIZED", message: "Unauthorized", details: nil)),
            dailyStatusResult: .success(DailyStatus(userActionsUsed: 0, userActionsRemaining: 1, bandeiraActionsUsed: nil, bandeiraActionCap: nil))
        )
        let uploadStub = RunUploadServiceStub(results: [])
        let viewModel = RunsViewModel(session: SessionStore(), runService: service, uploadService: uploadStub)

        await viewModel.load()

        XCTAssertTrue(viewModel.runs.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "API Error: Unauthorized")
    }

    private func makeRun() -> Run {
        Run(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            distance: 5.0,
            duration: 1800,
            startTime: "2024-01-01T10:00:00Z",
            endTime: "2024-01-01T10:30:00Z",
            isLoopValid: true,
            loopDistance: 5000,
            territoryAction: nil,
            targetTileId: nil,
            isValidForTerritory: true,
            fraudFlags: [],
            createdAt: "2024-01-01T10:30:00Z"
        )
    }
}

private final class RunServiceStub: RunServiceProtocol {
    let runsResult: Result<[Run], Error>
    let dailyStatusResult: Result<DailyStatus, Error>
    var submitResult: Result<RunSubmissionResult, Error>

    init(runsResult: Result<[Run], Error>, dailyStatusResult: Result<DailyStatus, Error>) {
        self.runsResult = runsResult
        self.dailyStatusResult = dailyStatusResult
        self.submitResult = .success(RunSubmissionResult(
            run: Run(
                id: UUID().uuidString,
                userId: UUID().uuidString,
                distance: 1,
                duration: 60,
                startTime: "2024-01-01T00:00:00Z",
                endTime: "2024-01-01T00:01:00Z",
                isLoopValid: true,
                loopDistance: 1,
                territoryAction: nil,
                targetTileId: nil,
                isValidForTerritory: true,
                fraudFlags: [],
                createdAt: "2024-01-01T00:01:00Z"
            ),
            loopValidation: LoopValidation(
                isValid: true,
                distance: 1,
                duration: 60,
                closingDistance: 0,
                tilesCovered: [],
                primaryTile: nil,
                primaryTileCoverage: 0,
                fraudFlags: [],
                failureReasons: []
            ),
            territoryResult: nil,
            turnResult: nil,
            dailyActionsRemaining: 0
        ))
    }

    func submitRunGpx(fileURL: URL) async throws -> RunSubmissionResult {
        try submitResult.get()
    }

    func submitRunCoordinates(coordinates: [CLLocationCoordinate2D], timestamps: [Int]) async throws -> RunSubmissionResult {
        try submitResult.get()
    }

    func getMyRuns() async throws -> [Run] {
        try runsResult.get()
    }

    func getDailyStatus() async throws -> DailyStatus {
        try dailyStatusResult.get()
    }
}

private struct RunUploadServiceStub: RunUploadServiceProtocol {
    let results: [RunSubmissionResult]

    func uploadPendingSessions() async -> [RunSubmissionResult] {
        results
    }
}
