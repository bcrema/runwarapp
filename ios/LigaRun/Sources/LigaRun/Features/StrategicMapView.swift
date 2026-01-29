import SwiftUI
import MapboxMaps

struct StrategicMapView: View {
    @State private var viewport = Viewport.camera(
        center: CLLocationCoordinate2D(latitude: -25.4284, longitude: -49.2733),
        zoom: 14,
        bearing: 0,
        pitch: 0
    )

    var body: some View {
        Map(viewport: $viewport)
            .mapStyle(.standard)
            .ignoresSafeArea()
    }
}
