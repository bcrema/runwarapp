import SwiftUI
import MapboxMaps

struct MissionSummaryView: View {
    let distance: Double // meters
    let duration: TimeInterval
    let quadrasConquered: Int
    let loopValid: Bool
    let actionsUsed: Int
    let actionCap: Int
    let routeCoordinates: [CLLocationCoordinate2D]
    @State private var viewport = Viewport.camera(
        center: CLLocationCoordinate2D(latitude: -25.43, longitude: -49.27),
        zoom: 13,
        bearing: 0,
        pitch: 0
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Map Snapshot Area
                ZStack(alignment: .bottomLeading) {
                    Map(viewport: $viewport)
                         .mapStyle(.standard) // Light style
                         .ignoresSafeArea()
                         .frame(height: 300)
                         .disabled(true) // Static interaction
                         .onAppear {
                             updateViewport(using: routeCoordinates)
                         }
                         .onChange(of: routeCoordinates) { newCoordinates in
                             updateViewport(using: newCoordinates)
                         }
                    
                    // Date Overlay
                    HStack {
                        Image(systemName: "calendar")
                        Text(Date.now.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.caption)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding()
                }
                
                // Header
                VStack(spacing: 8) {
                    Text("Run Complete")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Morning Run • \(String(format: "%.2f", distance / 1000)) km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Stats Row
                HStack(spacing: 40) {
                    StatBubble(icon: "figure.run", value: String(format: "%.1f", distance / 1000), unit: "km", label: "Distance")
                    StatBubble(icon: "clock", value: formatDuration(duration), unit: "min", label: "Time")
                    StatBubble(icon: "hexagon", value: "\(quadrasConquered)", unit: "", label: "Quadras")
                }
                
                // Loop Validation Card
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: loopValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(loopValid ? .green : .red)
                        Text(loopValid ? "Perfect Loop! • >1.2km" : "Loop Invalid")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Action Log
                    if quadrasConquered > 0 {
                        ActionRow(icon: "flag.fill", color: .green, text: "Conquered Quadra #802", badge: "+100 Shield")
                    } else {
                        Text("No territories affected this run.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
                
                // Daily Cap
                HStack {
                    Text("Actions Today")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    ProgressView(value: Double(actionsUsed), total: Double(actionCap))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 100)
                    Text("\(actionsUsed) / \(actionCap)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(50)
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)"
    }

    private func updateViewport(using coordinates: [CLLocationCoordinate2D]) {
        guard let bounds = coordinateBounds(for: coordinates) else { return }
        let center = CLLocationCoordinate2D(
            latitude: (bounds.min.latitude + bounds.max.latitude) / 2,
            longitude: (bounds.min.longitude + bounds.max.longitude) / 2
        )
        let zoom = zoomLevel(for: bounds)
        viewport = Viewport.camera(center: center, zoom: zoom, bearing: 0, pitch: 0)
    }

    private func coordinateBounds(for coordinates: [CLLocationCoordinate2D]) -> (min: CLLocationCoordinate2D, max: CLLocationCoordinate2D)? {
        guard let first = coordinates.first else { return nil }
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for coordinate in coordinates.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        return (
            min: CLLocationCoordinate2D(latitude: minLat, longitude: minLon),
            max: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
        )
    }

    private func zoomLevel(for bounds: (min: CLLocationCoordinate2D, max: CLLocationCoordinate2D)) -> CGFloat {
        let latitudeSpan = abs(bounds.max.latitude - bounds.min.latitude)
        let longitudeSpan = abs(bounds.max.longitude - bounds.min.longitude)
        let minZoom: Double = 10
        let maxZoom: Double = 16
        let minSpanForMaxZoom = 360 / pow(2, maxZoom)
        let maxSpan = max(latitudeSpan, longitudeSpan, minSpanForMaxZoom)
        let zoom = log2(360 / maxSpan)
        let clampedZoom = min(max(zoom, minZoom), maxZoom)
        return CGFloat(clampedZoom)
    }
}

struct StatBubble: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.title3)
            }
            Text("\(value)\(unit)")
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ActionRow: View {
    let icon: String
    let color: Color
    let text: String
    let badge: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline)
            Spacer()
            Text(badge)
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(8)
        }
    }
}
