import Foundation
import CoreLocation

@MainActor
final class MapViewModel: ObservableObject {
    @Published var tiles: [Tile] = []
    @Published var selectedTile: Tile?
    @Published var focusCoordinate: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
    }

    func loadTiles(bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tiles = try await session.api.getTiles(bounds: bounds)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshDisputed() async {
        do {
            tiles = try await session.api.getDisputedTiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func focusOnTile(id: String) async {
        do {
            let tile = try await session.api.getTile(id: id)
            focusCoordinate = CLLocationCoordinate2D(latitude: tile.lat, longitude: tile.lng)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
