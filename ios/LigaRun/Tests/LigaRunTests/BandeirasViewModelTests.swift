import XCTest
@testable import LigaRun

@MainActor
final class BandeirasViewModelTests: XCTestCase {
    func testJoinUpdatesCurrentStateAndShowsImpactMessage() async {
        let joined = makeBandeira(id: "bandeira-red")
        let service = BandeirasServiceStub()
        service.joinResult = .success(joined)
        service.getBandeirasResult = .success([joined])

        var currentUser = makeUser(bandeiraId: nil)
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { currentUser },
            refreshUserAction: {
                currentUser.bandeiraId = joined.id
                currentUser.bandeiraName = joined.name
            }
        )

        await viewModel.join(bandeira: joined)

        XCTAssertEqual(viewModel.currentBandeiraId, joined.id)
        XCTAssertEqual(viewModel.bandeiras.first?.id, joined.id)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.noticeMessage?.contains("proxima corrida valida") == true)
    }

    func testLeaveClearsCurrentBandeiraState() async {
        let service = BandeirasServiceStub()
        service.leaveResult = .success(())
        service.getBandeirasResult = .success([])

        var currentUser = makeUser(bandeiraId: "bandeira-red")
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { currentUser },
            refreshUserAction: {
                currentUser.bandeiraId = nil
                currentUser.bandeiraName = nil
            }
        )

        await viewModel.leave()

        XCTAssertNil(viewModel.currentBandeiraId)
        XCTAssertTrue(viewModel.bandeiras.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.noticeMessage?.contains("acoes voltam para sua conta") == true)
    }

    func testCreateBandeiraSuccessAddsItemAndResetsForm() async {
        let created = makeBandeira(id: "novo-time", name: "Novo Time")
        let service = BandeirasServiceStub()
        service.createResult = .success(created)
        service.getBandeirasResult = .success([created])

        var currentUser = makeUser(bandeiraId: nil)
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { currentUser },
            refreshUserAction: { _ = currentUser.id }
        )

        viewModel.createName = "Novo Time"
        viewModel.createCategory = "SOCIAL"
        viewModel.createColor = "#123ABC"
        viewModel.createDescription = "Descricao do time"

        await viewModel.createBandeira()

        XCTAssertEqual(service.createdRequests.count, 1)
        XCTAssertEqual(viewModel.bandeiras.first?.id, created.id)
        XCTAssertEqual(viewModel.createName, "")
        XCTAssertEqual(viewModel.createCategory, "")
        XCTAssertEqual(viewModel.createColor, "#22C55E")
        XCTAssertEqual(viewModel.createDescription, "")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testCreateBandeiraErrorShowsApiMessage() async {
        let service = BandeirasServiceStub()
        service.createResult = .failure(APIError(error: "VALIDATION_ERROR", message: "Nome ja existe", details: nil))

        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { self.makeUser(bandeiraId: nil) },
            refreshUserAction: {}
        )

        viewModel.createName = "Duplicada"
        viewModel.createCategory = "SOCIAL"
        viewModel.createColor = "#22C55E"
        viewModel.createDescription = ""

        await viewModel.createBandeira()

        XCTAssertEqual(viewModel.errorMessage, "Nome ja existe")
        XCTAssertTrue(viewModel.bandeiras.isEmpty)
        XCTAssertEqual(service.createdRequests.count, 1)
    }

    private func makeBandeira(id: String, name: String = "Time Red") -> Bandeira {
        Bandeira(
            id: id,
            name: name,
            slug: name.lowercased().replacingOccurrences(of: " ", with: "-"),
            category: "SOCIAL",
            color: "#22C55E",
            logoUrl: nil,
            description: "Descricao",
            memberCount: 12,
            totalTiles: 7,
            createdById: "user-1",
            createdByUsername: "runner"
        )
    }

    private func makeUser(bandeiraId: String?) -> User {
        User(
            id: "user-1",
            email: "runner@example.com",
            username: "runner",
            avatarUrl: nil,
            isPublic: true,
            bandeiraId: bandeiraId,
            bandeiraName: bandeiraId == nil ? nil : "Time Red",
            role: "USER",
            totalRuns: 10,
            totalDistance: 42.0,
            totalTilesConquered: 5
        )
    }
}

@MainActor
private final class BandeirasServiceStub: BandeirasServiceProtocol {
    var getBandeirasResult: Result<[Bandeira], Error> = .success([])
    var searchResult: Result<[Bandeira], Error> = .success([])
    var createResult: Result<Bandeira, Error> = .failure(APIError(error: "NOT_CONFIGURED", message: "Missing stub", details: nil))
    var joinResult: Result<Bandeira, Error> = .failure(APIError(error: "NOT_CONFIGURED", message: "Missing stub", details: nil))
    var leaveResult: Result<Void, Error> = .failure(APIError(error: "NOT_CONFIGURED", message: "Missing stub", details: nil))
    var createdRequests: [CreateBandeiraRequest] = []

    func getBandeiras() async throws -> [Bandeira] {
        try getBandeirasResult.get()
    }

    func searchBandeiras(query: String) async throws -> [Bandeira] {
        try searchResult.get()
    }

    func createBandeira(request: CreateBandeiraRequest) async throws -> Bandeira {
        createdRequests.append(request)
        return try createResult.get()
    }

    func joinBandeira(id: String) async throws -> Bandeira {
        try joinResult.get()
    }

    func leaveBandeira() async throws {
        try leaveResult.get()
    }
}
