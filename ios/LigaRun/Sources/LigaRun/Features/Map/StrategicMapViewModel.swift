import Foundation
import MapboxMaps
import Combine

@MainActor
final class StrategicMapViewModel: ObservableObject {
    @Published var tiles: [Tile] = []
    @Published var selectedTile: Tile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tileService: TileService
    private var cancellables = Set<AnyCancellable>()
    
    // Cache to prevent re-fetching the same area too often if needed, 
    // but for now we'll just fetch on camera idle.
    
    init(session: SessionStore) {
        self.tileService = TileService(api: session.api)
    }
    
    func loadTiles(for bounds: CoordinateBounds) async {
        isLoading = true
        defer { isLoading = false }
        
        // Convert Mapbox CoordinateBounds to tuple expected by API
        let minLat = bounds.southwest.latitude
        let minLng = bounds.southwest.longitude
        let maxLat = bounds.northeast.latitude
        let maxLng = bounds.northeast.longitude
        
        do {
            let fetchedTiles = try await tileService.fetchTiles(in: (minLat, minLng, maxLat, maxLng))
            self.tiles = fetchedTiles
        } catch {
            print("Error fetching tiles: \(error)")
            // Optionally set errorMessage if we want to show a toast
        }
    }
    
    func selectTile(id: String) async {
        do {
            selectedTile = try await tileService.getTileDetails(id: id)
        } catch {
            print("Error fetching tile details: \(error)")
        }
    }
    
    // GeoJSON Feature Collection generation
    var hexGridFeatures: FeatureCollection {
        var features: [Feature] = []
        
        for tile in tiles {
            let ring = tile.boundaryCoordinates
            
            // Validate ring
            guard ring.count >= 3 else { continue }
            
            // Ensure closed loop
            var closedRing = ring
            if let first = ring.first, let last = ring.last {
                 if first.latitude != last.latitude || first.longitude != last.longitude {
                     closedRing.append(first)
                 }
            }
            
            let geometry = Polygon([closedRing])
            var feature = Feature(geometry: Geometry.polygon(geometry))
            
            let status = tile.isInDispute ? "DISPUTED" : (tile.ownerType != nil ? "OWNED" : "NEUTRAL")
            
            feature.properties = [
                "color": .string(tile.ownerColor ?? "#CCCCCC"),
                "status": .string(status),
                "id": .string(tile.id)
            ]
            features.append(feature)
        }
        
        return FeatureCollection(features: features)
    }
}
