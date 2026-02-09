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

        await viewModel.loadTiles(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))

        XCTAssertEqual(viewModel.tiles.map(\.id), ["tile-a", "tile-b"])
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

        await viewModel.refreshDisputed()

        XCTAssertEqual(viewModel.tiles.first?.id, "tile-dispute")
        XCTAssertTrue(viewModel.tiles.first?.isInDispute ?? false)
    }

    @MainActor
    func testFocusOnTileSetsFocusCoordinate() async {
        let tile = makeTileFixture(id: "tile-focus", lat: -25.4, lng: -49.3)
        let api = MapAPISpy(
            tilesResult: .success([]),
            disputedResult: .success([]),
            tileResult: .success(tile)
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.focusOnTile(id: "tile-focus")

        XCTAssertEqual(viewModel.focusCoordinate?.latitude ?? 0, -25.4, accuracy: 0.0001)
        XCTAssertEqual(viewModel.focusCoordinate?.longitude ?? 0, -49.3, accuracy: 0.0001)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testLoadTilesErrorSetsMessage() async {
        let api = MapAPISpy(
            tilesResult: .failure(APIError(error: "MAP_ERROR", message: "Falha no mapa", details: nil)),
            disputedResult: .success([]),
            tileResult: .success(makeTileFixture())
        )
        let viewModel = MapViewModel(session: SessionStore(), api: api)

        await viewModel.loadTiles(bounds: (minLat: -26, minLng: -50, maxLat: -25, maxLng: -49))

        XCTAssertEqual(viewModel.errorMessage, "Falha no mapa")
    }
}

@MainActor
private final class MapAPISpy: MapAPIProviding {
    let tilesResult: Result<[Tile], Error>
    let disputedResult: Result<[Tile], Error>
    let tileResult: Result<Tile, Error>

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
        try tilesResult.get()
    }

    func getDisputedTiles() async throws -> [Tile] {
        try disputedResult.get()
    }

    func getTile(id: String) async throws -> Tile {
        try tileResult.get()
    }
}
