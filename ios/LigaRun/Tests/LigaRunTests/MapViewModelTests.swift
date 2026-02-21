import XCTest
@testable import LigaRun

final class MapViewModelTests: XCTestCase {
    @MainActor
    func testLoadTilesRefreshesTileList() async {
        let tiles = [makeTileFixture(id: "tile-a"), makeTileFixture(id: "tile-b", isInDispute: true)]
        let api = MapAPISpy(
            tilesResult: .success(tiles),
            disputedResult: .success([]),
            tileResult: .success(makeTileFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadQuadras(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))

        XCTAssertEqual(viewModel.quadras.map(\.id), ["tile-a", "tile-b"])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testRefreshDisputedUpdatesTiles() async {
        let disputed = [makeTileFixture(id: "tile-dispute", isInDispute: true)]
        let api = MapAPISpy(
            tilesResult: .success([]),
            disputedResult: .success(disputed),
            tileResult: .success(makeTileFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.refreshDisputedQuadras()

        XCTAssertEqual(viewModel.quadras.first?.id, "tile-dispute")
        XCTAssertTrue(viewModel.quadras.first?.isInDispute ?? false)
    }

    @MainActor
    func testFocusOnQuadraSetsFocusCoordinate() async {
        let tile = makeTileFixture(id: "tile-focus", lat: -25.4, lng: -49.3)
        let api = MapAPISpy(
            tilesResult: .success([]),
            disputedResult: .success([]),
            tileResult: .success(tile)
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.focusOnQuadra(id: "tile-focus")

        XCTAssertEqual(viewModel.focusCoordinate?.latitude ?? 0, -25.4, accuracy: 0.0001)
        XCTAssertEqual(viewModel.focusCoordinate?.longitude ?? 0, -49.3, accuracy: 0.0001)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testFocusOnQuadraUpsertsLatestQuadraState() async {
        let staleTile = makeTileFixture(id: "tile-focus", shield: 10)
        let refreshedTile = makeTileFixture(id: "tile-focus", shield: 88, isInDispute: true)
        let api = MapAPISpy(
            tilesResult: .success([staleTile]),
            disputedResult: .success([]),
            tileResult: .success(refreshedTile)
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadQuadras(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))
        await viewModel.focusOnQuadra(id: "tile-focus")

        XCTAssertEqual(viewModel.quadras.count, 1)
        XCTAssertEqual(viewModel.quadras.first?.shield, 88)
        XCTAssertTrue(viewModel.quadras.first?.isInDispute ?? false)
    }

    @MainActor
    func testRefreshVisibleQuadrasUsesLastBounds() async {
        let tiles = [makeTileFixture(id: "tile-a"), makeTileFixture(id: "tile-b")]
        let api = MapAPISpy(
            tilesResult: .success(tiles),
            disputedResult: .success([]),
            tileResult: .success(makeTileFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)
        let bounds = (minLat: -26.5, minLng: -50.5, maxLat: -25.5, maxLng: -49.5)

        await viewModel.loadQuadras(bounds: bounds)
        await viewModel.refreshVisibleQuadras()

        XCTAssertEqual(api.getTilesCallCount, 2)
        XCTAssertEqual(api.lastBounds?.minLat, bounds.minLat)
        XCTAssertEqual(api.lastBounds?.maxLng, bounds.maxLng)
    }

    @MainActor
    func testQuadraStateSummaryCountsNeutralOwnedAndDisputed() async {
        let tiles = [
            makeTileFixture(id: "neutral", ownerType: nil, ownerName: nil, ownerColor: nil),
            makeTileFixture(id: "owned", ownerType: .solo),
            makeTileFixture(id: "disputed", ownerType: .bandeira, isInDispute: true)
        ]
        let api = MapAPISpy(
            tilesResult: .success(tiles),
            disputedResult: .success([]),
            tileResult: .success(makeTileFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadQuadras(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))

        XCTAssertEqual(viewModel.quadraStateSummary, QuadraStateSummary(neutral: 1, owned: 1, disputed: 1))
    }

    @MainActor
    func testLoadQuadrasErrorSetsMessage() async {
        let api = MapAPISpy(
            tilesResult: .failure(APIError(error: "MAP_ERROR", message: "Falha no mapa", details: nil)),
            disputedResult: .success([]),
            tileResult: .success(makeTileFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadQuadras(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))

        XCTAssertEqual(viewModel.errorMessage, "Falha no mapa")
    }

    @MainActor
    func testLoadQuadrasBadServerResponseSetsFriendlyMessage() async {
        let api = MapAPISpy(
            tilesResult: .failure(URLError(.badServerResponse)),
            disputedResult: .success([]),
            tileResult: .success(makeTileFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadQuadras(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))

        XCTAssertEqual(viewModel.errorMessage, "Serviço de mapa indisponível no momento. Tente novamente em instantes.")
    }

    @MainActor
    func testRefreshDisputedQuadrasTimedOutSetsFriendlyMessage() async {
        let api = MapAPISpy(
            tilesResult: .success([]),
            disputedResult: .failure(URLError(.timedOut)),
            tileResult: .success(makeTileFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.refreshDisputedQuadras()

        XCTAssertEqual(viewModel.errorMessage, "A requisição demorou demais. Tente novamente em instantes.")
    }
}

@MainActor
private final class MapAPISpy: MapAPIProviding {
    let tilesResult: Result<[Tile], Error>
    let disputedResult: Result<[Tile], Error>
    let tileResult: Result<Tile, Error>
    private(set) var getTilesCallCount = 0
    private(set) var lastBounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)?

    init(
        tilesResult: Result<[Tile], Error>,
        disputedResult: Result<[Tile], Error>,
        tileResult: Result<Tile, Error>
    ) {
        self.tilesResult = tilesResult
        self.disputedResult = disputedResult
        self.tileResult = tileResult
    }

    func getTiles(bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)) async throws -> [Tile] {
        getTilesCallCount += 1
        lastBounds = bounds
        return try tilesResult.get()
    }

    func getDisputedTiles() async throws -> [Tile] {
        try disputedResult.get()
    }

    func getTile(id: String) async throws -> Tile {
        try tileResult.get()
    }
}
