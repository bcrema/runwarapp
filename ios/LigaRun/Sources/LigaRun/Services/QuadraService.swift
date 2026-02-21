import Foundation

@MainActor
final class QuadraService {
    private let api: APIClient
    
    init(api: APIClient) {
        self.api = api
    }
    
    func fetchQuadras(in bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)) async throws -> [Tile] {
        return try await api.getQuadras(bounds: bounds)
    }
    
    func getQuadraDetails(id: String) async throws -> Tile {
        return try await api.getQuadra(id: id)
    }
    
    func getDisputedQuadras() async throws -> [Tile] {
        return try await api.getDisputedQuadras()
    }
}
