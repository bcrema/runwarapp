import Foundation

@MainActor
final class TileService {
    private let api: APIClient
    
    init(api: APIClient) {
        self.api = api
    }
    
    func fetchTiles(in bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)) async throws -> [Tile] {
        return try await api.getTiles(bounds: bounds)
    }
    
    func getTileDetails(id: String) async throws -> Tile {
        return try await api.getTile(id: id)
    }
    
    func getDisputedTiles() async throws -> [Tile] {
        return try await api.getDisputedTiles()
    }
}
