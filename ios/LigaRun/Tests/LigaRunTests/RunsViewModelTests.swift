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
        let formatter = ISO8601DateFormatter()
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(1800)
        let startTime = formatter.string(from: startDate)
        let endTime = formatter.string(from: endDate)
        Run(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            distance: 5.0,
            duration: 1800,
            startTime: startTime,
            endTime: endTime,
            isLoopValid: true,
            loopDistance: 5000,
            territoryAction: nil,
            targetTileId: nil,
            isValidForTerritory: true,
            fraudFlags: [],
            createdAt: endTime
        )
    }
}

private final class RunServiceStub: RunServiceProtocol {
    let runsResult: Result<[Run], Error>
    let dailyStatusResult: Result<DailyStatus, Error>

    init(runsResult: Result<[Run], Error>, dailyStatusResult: Result<DailyStatus, Error>) {
        self.runsResult = runsResult
        self.dailyStatusResult = dailyStatusResult
    }

    func submitRunGpx(fileURL: URL) async throws -> RunSubmissionResult {
        fatalError("submitRunGpx is not implemented for RunServiceStub in RunsViewModelTests")
    }

    func submitRunCoordinates(coordinates: [CLLocationCoordinate2D], timestamps: [Int]) async throws -> RunSubmissionResult {
        fatalError("submitRunCoordinates is not implemented for RunServiceStub in RunsViewModelTests")
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
