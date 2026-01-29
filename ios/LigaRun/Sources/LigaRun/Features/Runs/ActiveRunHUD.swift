import SwiftUI
import CoreLocation
import MapboxMaps

struct ActiveRunHUD: View {
    @ObservedObject private var session: SessionStore
    @StateObject private var mapViewModel: MapViewModel
    @StateObject private var runManager: CompanionRunManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentTile: Tile?
    @State private var focusCoordinate: CLLocationCoordinate2D?
    @State private var lastFocusLocation: CLLocation?

    private let tealColor = Color(red: 0/255, green: 200/255, blue: 150/255)

    init(session: SessionStore) {
        self.session = session
        _mapViewModel = StateObject(wrappedValue: MapViewModel(session: session))
        _runManager = StateObject(wrappedValue: CompanionRunManager())
    }

    var body: some View {
        ZStack(alignment: .top) {
            HexMapView(
                selectedTile: .constant(nil),
                tiles: mapViewModel.tiles,
                focusCoordinate: focusCoordinate,
                routeCoordinates: runManager.routeCoordinates,
                showsUserLocation: true,
                styleURI: .standard,
                onVisibleRegionChanged: { bounds in
                    Task { await mapViewModel.loadTiles(bounds: bounds.toTuple) }
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    statusPill
                    Button {
                        runManager.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal)

                Spacer()

                statsCard
            }
        }
        .onAppear {
            runManager.startIfNeeded()
        }
        .onChange(of: runManager.currentLocation) { _ in
            updateCurrentTile()
            updateFocusCoordinate()
        }
        .onReceive(mapViewModel.$tiles) { _ in
            updateCurrentTile()
        }
        .alert("Erro", isPresented: Binding(get: {
            mapViewModel.errorMessage != nil
        }, set: { newValue in
            if !newValue { mapViewModel.errorMessage = nil }
        })) {
            Button("OK", role: .cancel) {
                mapViewModel.errorMessage = nil
            }
        } message: {
            Text(mapViewModel.errorMessage ?? "")
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Image(systemName: currentTile?.isInDispute == true ? "flame.fill" : "shield.fill")
                .foregroundColor(currentTile?.isInDispute == true ? .orange : tealColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("Corrida em andamento")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(territoryStatusText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    private var territoryStatusText: String {
        guard let tile = currentTile else {
            return "Buscando território..."
        }
        let owner = tile.ownerName ?? "Território neutro"
        var parts = ["\(owner)", "Escudo \(tile.shield)%"]
        if tile.isInDispute {
            parts.append("Em disputa")
        }
        return "Tile #\(tile.id.prefix(6)) • " + parts.joined(separator: " • ")
    }

    private var statsCard: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            HStack(spacing: 32) {
                metricBlock(value: runManager.formattedDistance, label: "DISTÂNCIA")
                metricBlock(value: runManager.formattedPace, label: "PACE")
            }

            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: runManager.loopProgress)
                            .stroke(tealColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(), value: runManager.loopProgress)

                        VStack(spacing: 0) {
                            Text("\(String(format: "%.1f", runManager.distanceMeters / 1000))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("km")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("LOOP")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    withAnimation {
                        if runManager.state == .running {
                            runManager.pause()
                        } else {
                            runManager.resume()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(runManager.state == .running ? Color.black : tealColor)
                            .frame(width: 72, height: 72)
                            .shadow(color: (runManager.state == .running ? Color.black : tealColor).opacity(0.3), radius: 10, x: 0, y: 5)

                        Image(systemName: runManager.state == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(32, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: -5)
    }

    private func metricBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundColor(.secondary)
        }
    }

    private func updateCurrentTile() {
        guard let location = runManager.currentLocation else {
            currentTile = nil
            return
        }

        currentTile = mapViewModel.tiles.first { tile in
            GeoUtils.isPoint(location.coordinate, inside: tile.boundaryCoordinates)
        }
    }

    private func updateFocusCoordinate() {
        guard let location = runManager.currentLocation else { return }
        if let lastFocusLocation, location.distance(from: lastFocusLocation) < 20 {
            return
        }
        lastFocusLocation = location
        focusCoordinate = location.coordinate
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

private extension CoordinateBounds {
    var toTuple: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double) {
        (
            minLat: southwest.latitude,
            minLng: southwest.longitude,
            maxLat: northeast.latitude,
            maxLng: northeast.longitude
        )
    }
}
