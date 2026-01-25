import SwiftUI
import MapboxMaps

struct StrategicMapView: View {
    @StateObject private var viewModel: StrategicMapViewModel
    @State private var viewport = Viewport.camera(center: CLLocationCoordinate2D(latitude: -25.4284, longitude: -49.2733), zoom: 14, bearing: 0, pitch: 0)
    
    init(session: SessionStore) {
        _viewModel = StateObject(wrappedValue: StrategicMapViewModel(session: session))
    }
    
    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .bottom) {
                Map(viewport: $viewport) {
                    // Hex Grid Layer
                    GeoJSONSource(id: "hex-source")
                        .data(.featureCollection(viewModel.hexGridFeatures))
                    
                    FillLayer(id: "hex-fill-layer", source: "hex-source")
                        .fillColor(.expression(Exp(.get) { "color" }))
                        .fillOpacity(0.4)
                        .fillOutlineColor(UIColor.white)
                        .filter(Exp(.eq) {
                            Exp(.geometryType)
                            "Polygon"
                        })
                    
                    // Disputed/Symbol Layer
                    SymbolLayer(id: "hex-symbol-layer", source: "hex-source")
                        .iconImage("warning-icon")
                        .iconOpacity(1.0)
                        .filter(Exp(.eq) {
                            Exp(.get) { "status" }
                            "DISPUTED"
                        })
                }
                .mapStyle(.standard)
                .ignoresSafeArea()
                .onMapLoaded { _ in
                    fetchTiles(with: proxy)
                }
                .onLayerTapGesture("hex-fill-layer") { feature, context in
                    // Extract ID properties
                    if case let .string(id) = feature.properties?["id"] {
                         Task {
                             await viewModel.selectTile(id: id)
                         }
                         return true // Handle event
                    }
                    return false
                }
                
                // Refresh Button
                Button {
                    fetchTiles(with: proxy)
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Search this area")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(red: 0/255, green: 200/255, blue: 150/255)) // Teal/Mint
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.bottom, 24)
            }
            .sheet(item: $viewModel.selectedTile) { tile in
                TileDetailsView(tile: tile)
                    .presentationDetents([.fraction(0.3), .medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func fetchTiles(with proxy: MapProxy) {
        // ... (Keep existing fetch logic)
        if let map = proxy.map {
           // ... existing bounds logic is fine, just cleaning up UI above
           let options = CameraOptions(center: map.cameraState.center, zoom: map.cameraState.zoom)
           let center = map.cameraState.center
           let delta = 0.05
           let bounds = CoordinateBounds(
               southwest: CLLocationCoordinate2D(latitude: center.latitude - delta, longitude: center.longitude - delta),
               northeast: CLLocationCoordinate2D(latitude: center.latitude + delta, longitude: center.longitude + delta)
           )
           
           Task {
               await viewModel.loadTiles(for: bounds)
           }
        }
    }
}
