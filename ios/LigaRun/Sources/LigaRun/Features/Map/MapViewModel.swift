import Foundation
import CoreLocation

@MainActor
final class MapViewModel: ObservableObject {
    @Published var tiles: [Tile] = []
    @Published var selectedTile: Tile?
    @Published var focusCoordinate: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: MapAPIProviding

    init(session: SessionStore, api: MapAPIProviding? = nil) {
        self.api = api ?? session.api
    }

    func loadTiles(bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tiles = try await api.getTiles(bounds: bounds)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshDisputed() async {
        do {
            tiles = try await api.getDisputedTiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func focusOnTile(id: String) async {
        do {
            let tile = try await api.getTile(id: id)
            focusCoordinate = CLLocationCoordinate2D(latitude: tile.lat, longitude: tile.lng)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
