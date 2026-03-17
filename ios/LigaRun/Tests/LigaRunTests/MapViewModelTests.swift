import XCTest
@testable import LigaRun

final class MapViewModelTests: XCTestCase {
    @MainActor
    func testUpdateVisibleBoundsLoadsViewportForAllFilter() async {
        let bounds = (minLat: -26.0, minLng: -50.0, maxLat: -25.0, maxLng: -49.0)
        let api = MapAPISpy(
            viewportQuadrasResult: .success([makeQuadraFixture(id: "tile-a"), makeQuadraFixture(id: "tile-b", isInDispute: true)]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: makeSessionStore(), api: api)

        await viewModel.updateVisibleBounds(bounds, filter: .all)

        XCTAssertEqual(api.getQuadrasCallCount, 1)
        XCTAssertEqual(api.lastBounds?.minLat, bounds.minLat)
        XCTAssertEqual(viewModel.quadras.map(\.id), ["tile-a", "tile-b"])
        XCTAssertEqual(viewModel.activeFilter, .all)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.emptyState)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testSelectDisputedLoadsDedicatedEndpoint() async {
        let api = MapAPISpy(
            viewportQuadrasResult: .success([]),
            disputedQuadrasResult: .success([makeQuadraFixture(id: "tile-dispute", isInDispute: true)]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: makeSessionStore(), api: api)

        await viewModel.selectFilter(.disputed)

        XCTAssertEqual(api.getDisputedQuadrasCallCount, 1)
        XCTAssertEqual(viewModel.activeFilter, .disputed)
        XCTAssertEqual(viewModel.quadras.first?.id, "tile-dispute")
        XCTAssertTrue(viewModel.quadras.first?.isInDispute ?? false)
        XCTAssertNil(viewModel.emptyState)
    }

    @MainActor
    func testSelectMineLoadsCurrentUserQuadras() async {
        let session = makeSessionStore(user: makeMapUserFixture(id: "runner-1", bandeiraId: nil))
        let api = MapAPISpy(
            viewportQuadrasResult: .success([]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([makeQuadraFixture(id: "mine-1", ownerId: "runner-1")]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: session, api: api)

        await viewModel.selectFilter(.mine)

        XCTAssertEqual(api.getQuadrasByUserCallCount, 1)
        XCTAssertEqual(api.lastUserId, "runner-1")
        XCTAssertEqual(viewModel.quadras.map(\.id), ["mine-1"])
        XCTAssertNil(viewModel.emptyState)
    }

    @MainActor
    func testSelectMyBandeiraUsesFocusContextOverride() async {
        let session = makeSessionStore(user: makeMapUserFixture(id: "runner-1", bandeiraId: "band-own"))
        let api = MapAPISpy(
            viewportQuadrasResult: .success([]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([makeQuadraFixture(id: "band-quadra", ownerType: .bandeira, ownerId: "band-ranking")]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: session, api: api)

        await viewModel.selectFilter(.myBandeira, focusContext: .bandeira(bandeiraId: "band-ranking"))

        XCTAssertEqual(api.getQuadrasByBandeiraCallCount, 1)
        XCTAssertEqual(api.lastBandeiraId, "band-ranking")
        XCTAssertEqual(viewModel.quadras.map(\.id), ["band-quadra"])
        XCTAssertEqual(viewModel.contextualMessage, "Exibindo o territorio da bandeira selecionada no hub social.")
    }

    @MainActor
    func testSelectMineWithoutSessionShowsGuidanceEmptyState() async {
        let api = MapAPISpy(
            viewportQuadrasResult: .success([]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: makeSessionStore(), api: api)

        await viewModel.selectFilter(.mine)

        XCTAssertTrue(viewModel.quadras.isEmpty)
        XCTAssertEqual(viewModel.emptyState?.title, "Sessao necessaria")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(api.getQuadrasByUserCallCount, 0)
    }

    @MainActor
    func testSelectMyBandeiraWithoutBandeiraShowsGuidanceEmptyState() async {
        let session = makeSessionStore(user: makeMapUserFixture(id: "runner-1", bandeiraId: nil))
        let api = MapAPISpy(
            viewportQuadrasResult: .success([]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: session, api: api)

        await viewModel.selectFilter(.myBandeira)

        XCTAssertTrue(viewModel.quadras.isEmpty)
        XCTAssertEqual(viewModel.emptyState?.title, "Voce ainda nao tem bandeira")
        XCTAssertEqual(viewModel.contextualMessage, "Sem bandeira ativa: o filtro mostra um estado orientativo em vez de erro seco.")
        XCTAssertEqual(api.getQuadrasByBandeiraCallCount, 0)
    }

    @MainActor
    func testSelectDisputedEmptyStateIsUserFacing() async {
        let api = MapAPISpy(
            viewportQuadrasResult: .success([]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: makeSessionStore(), api: api)

        await viewModel.selectFilter(.disputed)

        XCTAssertEqual(viewModel.emptyState?.title, "Nenhuma disputa agora")
        XCTAssertEqual(viewModel.emptyState?.message, "Nao ha quadras em disputa no momento. Tente novamente em instantes ou volte para Todas.")
    }

    @MainActor
    func testUpdateVisibleBoundsDoesNotReloadViewportForNonAllFilters() async {
        let api = MapAPISpy(
            viewportQuadrasResult: .success([]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([makeQuadraFixture(id: "mine-1")]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let session = makeSessionStore(user: makeMapUserFixture(id: "runner-1", bandeiraId: nil))
        let viewModel = MapViewModel(session: session, api: api)

        await viewModel.updateVisibleBounds((minLat: -26.0, minLng: -50.0, maxLat: -25.0, maxLng: -49.0), filter: .mine)

        XCTAssertEqual(api.getQuadrasCallCount, 0)
        XCTAssertTrue(viewModel.quadras.isEmpty)
    }

    @MainActor
    func testRefreshVisibleQuadrasReusesLastViewportBounds() async {
        let bounds = (minLat: -26.5, minLng: -50.5, maxLat: -25.5, maxLng: -49.5)
        let api = MapAPISpy(
            viewportQuadrasResult: .success([makeQuadraFixture(id: "tile-a"), makeQuadraFixture(id: "tile-b")]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: makeSessionStore(), api: api)

        await viewModel.updateVisibleBounds(bounds, filter: .all)
        await viewModel.refreshVisibleQuadras()

        XCTAssertEqual(api.getQuadrasCallCount, 2)
        XCTAssertEqual(api.lastBounds?.maxLng, bounds.maxLng)
    }

    @MainActor
    func testFocusOnQuadraSetsFocusCoordinate() async {
        let tile = makeQuadraFixture(id: "tile-focus", lat: -25.4, lng: -49.3)
        let api = MapAPISpy(
            viewportQuadrasResult: .success([]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(tile)
        )
        let viewModel = MapViewModel(session: makeSessionStore(), api: api)

        await viewModel.focusOnQuadra(id: "tile-focus")

        XCTAssertEqual(viewModel.focusCoordinate?.latitude ?? 0, -25.4, accuracy: 0.0001)
        XCTAssertEqual(viewModel.focusCoordinate?.longitude ?? 0, -49.3, accuracy: 0.0001)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testFocusOnQuadraUpsertsLatestQuadraState() async {
        let staleTile = makeQuadraFixture(id: "tile-focus", shield: 10)
        let refreshedTile = makeQuadraFixture(id: "tile-focus", shield: 88, isInDispute: true)
        let api = MapAPISpy(
            viewportQuadrasResult: .success([staleTile]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(refreshedTile)
        )
        let viewModel = MapViewModel(session: makeSessionStore(), api: api)

        await viewModel.updateVisibleBounds((minLat: -26.0, minLng: -50.0, maxLat: -25.0, maxLng: -49.0), filter: .all)
        await viewModel.focusOnQuadra(id: "tile-focus")

        XCTAssertEqual(viewModel.quadras.count, 1)
        XCTAssertEqual(viewModel.quadras.first?.shield, 88)
        XCTAssertTrue(viewModel.quadras.first?.isInDispute ?? false)
    }

    @MainActor
    func testQuadraStateSummaryCountsNeutralOwnedAndDisputed() async {
        let api = MapAPISpy(
            viewportQuadrasResult: .success([
                makeQuadraFixture(id: "neutral", ownerType: nil, ownerName: nil, ownerColor: nil),
                makeQuadraFixture(id: "owned", ownerType: .solo),
                makeQuadraFixture(id: "disputed", ownerType: .bandeira, isInDispute: true)
            ]),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: makeSessionStore(), api: api)

        await viewModel.updateVisibleBounds((minLat: -26.0, minLng: -50.0, maxLat: -25.0, maxLng: -49.0), filter: .all)

        XCTAssertEqual(viewModel.quadraStateSummary, QuadraStateSummary(neutral: 1, owned: 1, disputed: 1))
    }

    @MainActor
    func testSelectAllErrorSetsFriendlyMessage() async {
        let api = MapAPISpy(
            viewportQuadrasResult: .failure(APIError(error: "MAP_ERROR", message: "Falha no mapa", details: nil)),
            disputedQuadrasResult: .success([]),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: makeSessionStore(), api: api)

        await viewModel.updateVisibleBounds((minLat: -26.0, minLng: -50.0, maxLat: -25.0, maxLng: -49.0), filter: .all)

        XCTAssertEqual(viewModel.errorMessage, "Falha no mapa")
        XCTAssertTrue(viewModel.quadras.isEmpty)
    }

    @MainActor
    func testSelectDisputedTimedOutSetsFriendlyMessage() async {
        let api = MapAPISpy(
            viewportQuadrasResult: .success([]),
            disputedQuadrasResult: .failure(URLError(.timedOut)),
            userQuadrasResult: .success([]),
            bandeiraQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: makeSessionStore(), api: api)

        await viewModel.selectFilter(.disputed)

        XCTAssertEqual(viewModel.errorMessage, "A requisição demorou demais. Tente novamente em instantes.")
    }
}

@MainActor
private final class MapAPISpy: MapAPIProviding {
    let viewportQuadrasResult: Result<[Tile], Error>
    let disputedQuadrasResult: Result<[Tile], Error>
    let userQuadrasResult: Result<[Tile], Error>
    let bandeiraQuadrasResult: Result<[Tile], Error>
    let quadraResult: Result<Tile, Error>
    private(set) var getQuadrasCallCount = 0
    private(set) var getDisputedQuadrasCallCount = 0
    private(set) var getQuadrasByUserCallCount = 0
    private(set) var getQuadrasByBandeiraCallCount = 0
    private(set) var lastBounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)?
    private(set) var lastUserId: String?
    private(set) var lastBandeiraId: String?

    init(
        viewportQuadrasResult: Result<[Tile], Error>,
        disputedQuadrasResult: Result<[Tile], Error>,
        userQuadrasResult: Result<[Tile], Error>,
        bandeiraQuadrasResult: Result<[Tile], Error>,
        quadraResult: Result<Tile, Error>
    ) {
        self.viewportQuadrasResult = viewportQuadrasResult
        self.disputedQuadrasResult = disputedQuadrasResult
        self.userQuadrasResult = userQuadrasResult
        self.bandeiraQuadrasResult = bandeiraQuadrasResult
        self.quadraResult = quadraResult
    }

    func getQuadras(bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)) async throws -> [Tile] {
        getQuadrasCallCount += 1
        lastBounds = bounds
        return try viewportQuadrasResult.get()
    }

    func getDisputedQuadras() async throws -> [Tile] {
        getDisputedQuadrasCallCount += 1
        return try disputedQuadrasResult.get()
    }

    func getQuadrasByUser(userId: String) async throws -> [Tile] {
        getQuadrasByUserCallCount += 1
        lastUserId = userId
        return try userQuadrasResult.get()
    }

    func getQuadrasByBandeira(bandeiraId: String) async throws -> [Tile] {
        getQuadrasByBandeiraCallCount += 1
        lastBandeiraId = bandeiraId
        return try bandeiraQuadrasResult.get()
    }

    func getQuadra(id: String) async throws -> Tile {
        try quadraResult.get()
    }
}

@MainActor
private func makeSessionStore(user: User? = nil) -> SessionStore {
    let session = SessionStore()
    session.currentUser = user
    return session
}

private func makeMapUserFixture(
    id: String = "runner-1",
    bandeiraId: String? = "band-1"
) -> User {
    User(
        id: id,
        email: "\(id)@ligarun.app",
        username: id,
        avatarUrl: nil,
        isPublic: true,
        bandeiraId: bandeiraId,
        bandeiraName: bandeiraId.map { _ in "Liga" },
        role: "runner",
        totalRuns: 0,
        totalDistance: 0,
        totalTilesConquered: 0
    )
}
