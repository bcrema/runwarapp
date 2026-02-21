import XCTest
@testable import LigaRun

final class MapViewModelTests: XCTestCase {
    @MainActor
    func testLoadQuadrasRefreshesQuadraList() async {
        let tiles = [makeQuadraFixture(id: "tile-a"), makeQuadraFixture(id: "tile-b", isInDispute: true)]
        let api = MapAPISpy(
            quadrasResult: .success(tiles),
            disputedQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadQuadras(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))

        XCTAssertEqual(viewModel.tiles.map(\.id), ["tile-a", "tile-b"])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testRefreshDisputedUpdatesTiles() async {
        let disputed = [makeQuadraFixture(id: "tile-dispute", isInDispute: true)]
        let api = MapAPISpy(
            quadrasResult: .success([]),
            disputedQuadrasResult: .success(disputed),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.refreshDisputed()

        XCTAssertEqual(viewModel.tiles.first?.id, "tile-dispute")
        XCTAssertTrue(viewModel.tiles.first?.isInDispute ?? false)
    }

    @MainActor
    func testFocusOnQuadraSetsFocusCoordinate() async {
        let tile = makeQuadraFixture(id: "tile-focus", lat: -25.4, lng: -49.3)
        let api = MapAPISpy(
            quadrasResult: .success([]),
            disputedQuadrasResult: .success([]),
            quadraResult: .success(tile)
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

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
            quadrasResult: .success([staleTile]),
            disputedQuadrasResult: .success([]),
            quadraResult: .success(refreshedTile)
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadQuadras(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))
        await viewModel.focusOnQuadra(id: "tile-focus")

        XCTAssertEqual(viewModel.tiles.count, 1)
        XCTAssertEqual(viewModel.tiles.first?.shield, 88)
        XCTAssertTrue(viewModel.tiles.first?.isInDispute ?? false)
    }

    @MainActor
    func testRefreshVisibleQuadrasUsesLastBounds() async {
        let tiles = [makeQuadraFixture(id: "tile-a"), makeQuadraFixture(id: "tile-b")]
        let api = MapAPISpy(
            quadrasResult: .success(tiles),
            disputedQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)
        let bounds = (minLat: -26.5, minLng: -50.5, maxLat: -25.5, maxLng: -49.5)

        await viewModel.loadQuadras(bounds: bounds)
        await viewModel.refreshVisibleQuadras()

        XCTAssertEqual(api.getQuadrasCallCount, 2)
        XCTAssertEqual(api.lastBounds?.minLat, bounds.minLat)
        XCTAssertEqual(api.lastBounds?.maxLng, bounds.maxLng)
    }

    @MainActor
    func testTileStateSummaryCountsNeutralOwnedAndDisputed() async {
        let tiles = [
            makeQuadraFixture(id: "neutral", ownerType: nil, ownerName: nil, ownerColor: nil),
            makeQuadraFixture(id: "owned", ownerType: .solo),
            makeQuadraFixture(id: "disputed", ownerType: .bandeira, isInDispute: true)
        ]
        let api = MapAPISpy(
            quadrasResult: .success(tiles),
            disputedQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadQuadras(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))

        XCTAssertEqual(viewModel.tileStateSummary, TileStateSummary(neutral: 1, owned: 1, disputed: 1))
    }

    @MainActor
    func testLoadQuadrasErrorSetsMessage() async {
        let api = MapAPISpy(
            quadrasResult: .failure(APIError(error: "MAP_ERROR", message: "Falha no mapa", details: nil)),
            disputedQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadQuadras(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))

        XCTAssertEqual(viewModel.errorMessage, "Falha no mapa")
    }

    @MainActor
    func testLoadQuadrasBadServerResponseSetsFriendlyMessage() async {
        let api = MapAPISpy(
            quadrasResult: .failure(URLError(.badServerResponse)),
            disputedQuadrasResult: .success([]),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadQuadras(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))

        XCTAssertEqual(viewModel.errorMessage, "Serviço de mapa indisponível no momento. Tente novamente em instantes.")
    }

    @MainActor
    func testRefreshDisputedTimedOutSetsFriendlyMessage() async {
        let api = MapAPISpy(
            quadrasResult: .success([]),
            disputedQuadrasResult: .failure(URLError(.timedOut)),
            quadraResult: .success(makeQuadraFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.refreshDisputed()

        XCTAssertEqual(viewModel.errorMessage, "A requisição demorou demais. Tente novamente em instantes.")
    }
}

@MainActor
private final class MapAPISpy: MapAPIProviding {
    let quadrasResult: Result<[Tile], Error>
    let disputedQuadrasResult: Result<[Tile], Error>
    let quadraResult: Result<Tile, Error>
    private(set) var getQuadrasCallCount = 0
    private(set) var lastBounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)?

    init(
        quadrasResult: Result<[Tile], Error>,
        disputedQuadrasResult: Result<[Tile], Error>,
        quadraResult: Result<Tile, Error>
    ) {
        self.quadrasResult = quadrasResult
        self.disputedQuadrasResult = disputedQuadrasResult
        self.quadraResult = quadraResult
    }

    func getQuadras(bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)) async throws -> [Tile] {
        getQuadrasCallCount += 1
        lastBounds = bounds
        return try quadrasResult.get()
    }

    func getDisputedQuadras() async throws -> [Tile] {
        try disputedQuadrasResult.get()
    }

    func getQuadra(id: String) async throws -> Tile {
        try quadraResult.get()
    }
}
