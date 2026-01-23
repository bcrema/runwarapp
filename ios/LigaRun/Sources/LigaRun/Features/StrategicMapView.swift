import SwiftUI
import MapboxMaps

struct StrategicMapView: View {
    @State private var viewport = Viewport.camera(center: CLLocationCoordinate2D(latitude: -25.4284, longitude: -49.2733), zoom: 14, bearing: 0, pitch: 0)
    
    var body: some View {
        Map(viewport: $viewport) {
            // Hex Grid Layer
            GeoJSONSource(id: "hex-source")
                .data(.featureCollection(FeatureCollection(features: []))) // Placeholder for Grid Data
            
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
        .mapStyle(.standard) // Light style equivalent
        .ignoresSafeArea()
        .onAppear {
            // TODO: Load initial data
        }
    }
}
