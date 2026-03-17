import XCTest
@testable import LigaRun

final class BandeirasViewModelTests: XCTestCase {
    @MainActor
    func testCreateJoinsLoadAndRefreshesUser() async {
        let bandeira = makeBandeiraFixture(id: "new-b", name: "Nova Bandeira")
        let service = BandeirasServiceSpy()
        service.bandeiras = [bandeira]

        var refreshCalls = 0
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in
                refreshCalls += 1
            }
        )

        await viewModel.create(name: "Nova Bandeira", category: "running", color: "#FF6600", description: "Time")

        XCTAssertEqual(service.createdRequests.count, 1)
        XCTAssertEqual(viewModel.bandeiras.first?.id, "new-b")
        XCTAssertEqual(viewModel.exploreStatus, .loaded)
        XCTAssertEqual(refreshCalls, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testJoinReloadsAndRefreshesUser() async {
        let bandeira = makeBandeiraFixture(id: "join-1", name: "Liga Join")
        let service = BandeirasServiceSpy()
        service.bandeiras = [bandeira]

        var refreshCalls = 0
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in
                refreshCalls += 1
            }
        )

        await viewModel.join(bandeira: bandeira)

        XCTAssertEqual(service.joinCalls, ["join-1"])
        XCTAssertEqual(viewModel.bandeiras.first?.name, "Liga Join")
        XCTAssertEqual(viewModel.exploreStatus, .loaded)
        XCTAssertEqual(refreshCalls, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testLeaveReloadsAndRefreshesUser() async {
        let service = BandeirasServiceSpy()
        service.bandeiras = [makeBandeiraFixture(id: "left")]

        var refreshCalls = 0
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in
                refreshCalls += 1
            }
        )

        await viewModel.leave()

        XCTAssertEqual(service.leaveCalls, 1)
        XCTAssertEqual(viewModel.exploreStatus, .loaded)
        XCTAssertEqual(refreshCalls, 1)
    }

    @MainActor
    func testJoinFailureSetsErrorMessage() async {
        let bandeira = makeBandeiraFixture(id: "error-b")
        let service = BandeirasServiceSpy()
        service.joinError = APIError(error: "JOIN_ERROR", message: "Nao foi possivel entrar", details: nil)
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        await viewModel.join(bandeira: bandeira)

        XCTAssertEqual(viewModel.errorMessage, "Nao foi possivel entrar")
    }

    @MainActor
    func testLoadExplorePublishesEmptyStateWithoutTouchingRanking() async {
        let service = BandeirasServiceSpy()
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.exploreStatus, .empty)
        XCTAssertTrue(viewModel.shouldShowExploreEmptyState)
        XCTAssertEqual(viewModel.exploreEmptyStateTitle, "Nenhuma bandeira disponivel")
        XCTAssertEqual(viewModel.rankingStatus, .idle)
    }

    @MainActor
    func testLoadRankingPublishesLoadingAndLoadedStateIndependently() async {
        let service = BandeirasServiceSpy()
        let gate = AsyncGate()
        service.rankings = [
            makeBandeiraFixture(id: "rank-1", name: "Primeira"),
            makeBandeiraFixture(id: "rank-2", name: "Segunda")
        ]
        service.rankingGate = gate

        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        let task = Task { await viewModel.loadRanking() }
        await Task.yield()

        XCTAssertTrue(viewModel.isRankingLoading)
        XCTAssertTrue(viewModel.rankingBandeiras.isEmpty)
        XCTAssertEqual(viewModel.exploreStatus, .idle)

        await gate.open()
        await task.value

        XCTAssertEqual(viewModel.rankingStatus, .loaded)
        XCTAssertEqual(viewModel.rankingBandeiras.map(\.id), ["rank-1", "rank-2"])
        XCTAssertFalse(viewModel.isRankingLoading)
        XCTAssertEqual(viewModel.exploreStatus, .idle)
    }

    @MainActor
    func testLoadRankingFailureIsIsolatedFromExploreSurface() async {
        let service = BandeirasServiceSpy()
        service.bandeiras = [makeBandeiraFixture(id: "explore-1", name: "Explorar")]
        service.rankingsError = APIError(error: "RANKING_DOWN", message: "Ranking indisponivel", details: nil)

        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        await viewModel.load()
        await viewModel.loadRanking()

        XCTAssertEqual(viewModel.exploreStatus, .loaded)
        XCTAssertEqual(viewModel.bandeiras.map(\.id), ["explore-1"])
        XCTAssertEqual(viewModel.rankingStatus, .failed("Ranking indisponivel"))
        XCTAssertEqual(viewModel.rankingErrorMessage, "Ranking indisponivel")
        XCTAssertTrue(viewModel.rankingBandeiras.isEmpty)
    }

    @MainActor
    func testLoadRankingPublishesEmptyState() async {
        let service = BandeirasServiceSpy()
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        await viewModel.activate(tab: .ranking)

        XCTAssertEqual(viewModel.rankingStatus, .empty)
        XCTAssertTrue(viewModel.shouldShowRankingEmptyState)
        XCTAssertEqual(viewModel.rankingEmptyStateTitle, "Ranking indisponivel")
    }

    @MainActor
    func testRequestMapFocusEmitsCanonicalIntent() {
        let bandeira = makeBandeiraFixture(id: "rank-map", name: "Liga Mapa")
        let service = BandeirasServiceSpy()
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        viewModel.requestMapFocus(for: bandeira)

        XCTAssertEqual(
            viewModel.pendingMapIntent,
            BandeirasMapIntent(
                filter: .myBandeira,
                focusContext: .bandeira(bandeiraId: "rank-map")
            )
        )

        viewModel.consumePendingMapIntent()

        XCTAssertNil(viewModel.pendingMapIntent)
    }
}

@MainActor
private final class BandeirasServiceSpy: BandeirasServiceProtocol {
    var bandeiras: [Bandeira] = []
    var rankings: [Bandeira] = []
    var joinError: Error?
    var rankingsError: Error?
    var rankingGate: AsyncGate?
    private(set) var createdRequests: [CreateBandeiraRequest] = []
    private(set) var joinCalls: [String] = []
    private(set) var leaveCalls = 0

    func getBandeiras() async throws -> [Bandeira] {
        bandeiras
    }

    func getBandeiraRankings() async throws -> [Bandeira] {
        if let rankingGate {
            await rankingGate.wait()
        }
        if let rankingsError {
            throw rankingsError
        }
        return rankings
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

private actor AsyncGate {
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func open() {
        continuation?.resume()
        continuation = nil
    }
}
