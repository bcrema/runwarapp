import XCTest
@testable import LigaRun

final class BandeirasViewModelTests: XCTestCase {
    @MainActor
    func testCreateJoinsLoadAndRefreshesUser() async {
        let bandeira = makeBandeiraFixture(id: "new-b", name: "Nova Bandeira")
        let api = BandeirasAPISpy()
        api.bandeiras = [bandeira]

        var refreshCalls = 0
        let viewModel = BandeirasViewModel(
            session: SessionStore(),
            api: api,
            refreshUser: { () async throws in
                refreshCalls += 1
            }
        )

        await viewModel.create(name: "Nova Bandeira", category: "running", color: "#FF6600", description: "Time")

        XCTAssertEqual(api.createdRequests.count, 1)
        XCTAssertEqual(viewModel.bandeiras.first?.id, "new-b")
        XCTAssertEqual(refreshCalls, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testJoinReloadsAndRefreshesUser() async {
        let bandeira = makeBandeiraFixture(id: "join-1", name: "Liga Join")
        let api = BandeirasAPISpy()
        api.bandeiras = [bandeira]

        var refreshCalls = 0
        let viewModel = BandeirasViewModel(
            session: SessionStore(),
            api: api,
            refreshUser: { () async throws in
                refreshCalls += 1
            }
        )

        await viewModel.join(bandeira: bandeira)

        XCTAssertEqual(api.joinCalls, ["join-1"])
        XCTAssertEqual(viewModel.bandeiras.first?.name, "Liga Join")
        XCTAssertEqual(refreshCalls, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testLeaveReloadsAndRefreshesUser() async {
        let api = BandeirasAPISpy()
        api.bandeiras = [makeBandeiraFixture(id: "left")]

        var refreshCalls = 0
        let viewModel = BandeirasViewModel(
            session: SessionStore(),
            api: api,
            refreshUser: { () async throws in
                refreshCalls += 1
            }
        )

        await viewModel.leave()

        XCTAssertEqual(api.leaveCalls, 1)
        XCTAssertEqual(refreshCalls, 1)
    }

    @MainActor
    func testJoinFailureSetsErrorMessage() async {
        let bandeira = makeBandeiraFixture(id: "error-b")
        let api = BandeirasAPISpy()
        api.joinError = APIError(error: "JOIN_ERROR", message: "Nao foi possivel entrar", details: nil)
        let viewModel = BandeirasViewModel(session: SessionStore(), api: api, refreshUser: { () async throws in })

        await viewModel.join(bandeira: bandeira)

        XCTAssertEqual(viewModel.errorMessage, "Nao foi possivel entrar")
    }
}

@MainActor
private final class BandeirasAPISpy: BandeirasAPIProviding {
    var bandeiras: [Bandeira] = []
    var joinError: Error?
    private(set) var createdRequests: [CreateBandeiraRequest] = []
    private(set) var joinCalls: [String] = []
    private(set) var leaveCalls = 0

    func getBandeiras() async throws -> [Bandeira] {
        bandeiras
    }

    func searchBandeiras(query: String) async throws -> [Bandeira] {
        bandeiras.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func createBandeira(request: CreateBandeiraRequest) async throws -> Bandeira {
        createdRequests.append(request)
        return bandeiras.first ?? makeBandeiraFixture(id: "created", name: request.name)
    }

    func joinBandeira(id: String) async throws -> Bandeira {
        if let joinError {
            throw joinError
        }
        joinCalls.append(id)
        return bandeiras.first ?? makeBandeiraFixture(id: id)
    }

    func leaveBandeira() async throws {
        leaveCalls += 1
    }
}
