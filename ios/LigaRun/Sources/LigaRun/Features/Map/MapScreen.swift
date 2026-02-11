import SwiftUI
import MapboxMaps

struct MapScreen: View {
    @ObservedObject private var session: SessionStore
    @StateObject private var viewModel: MapViewModel
    @State private var showingActiveRun = false

    init(session: SessionStore) {
        self.session = session
        _viewModel = StateObject(wrappedValue: MapViewModel(session: session))
    }

    var body: some View {
        ZStack {
            HexMapView(
                selectedTile: $viewModel.selectedTile,
                tiles: viewModel.tiles,
                focusCoordinate: viewModel.focusCoordinate,
                onVisibleRegionChanged: { bounds in
                    Task { await viewModel.loadTiles(bounds: bounds.toTuple) }
                },
                onTileTapped: { tile in
                    viewModel.selectedTile = tile
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    tileStateLegend
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView("Carregando tiles...")
                                .padding(8)
                                .background(.ultraThinMaterial, in: Capsule())
                        }

                        Button {
                            Task { await viewModel.refreshDisputed() }
                        } label: {
                            Label("Ver disputas", systemImage: "flame")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                Spacer()

                Button {
                    showingActiveRun = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.run")
                        Text("Acompanhar corrida")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .sheet(item: $viewModel.selectedTile) { tile in
            if #available(iOS 16, *) {
                TileDetailView(tile: tile)
                    .presentationDetents([.fraction(0.4), .medium])
            } else {
                TileDetailView(tile: tile)
            }
        }
        .alert("Erro", isPresented: Binding(get: {
            viewModel.errorMessage != nil
        }, set: { newValue in
            if !newValue { viewModel.errorMessage = nil }
        })) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: session.mapFocusTileId) { newValue in
            guard let tileId = newValue else { return }
            Task {
                await viewModel.refreshVisibleTiles()
                await viewModel.focusOnTile(id: tileId)
                session.mapFocusTileId = nil
            }
        }
        .onChange(of: session.selectedTabIndex) { newValue in
            guard newValue == 0 else { return }
            Task {
                await viewModel.refreshVisibleTiles()
            }
        }
        .fullScreenCover(isPresented: $showingActiveRun) {
            ActiveRunHUD(session: session)
        }
    }

    private var tileStateLegend: some View {
        let summary = viewModel.tileStateSummary
        return VStack(alignment: .leading, spacing: 6) {
            Label("\(summary.neutral) neutro", systemImage: "circle.fill")
                .foregroundColor(.gray)
            Label("\(summary.owned) dominado", systemImage: "shield.fill")
                .foregroundColor(.green)
            Label("\(summary.disputed) disputa", systemImage: "flame.fill")
                .foregroundColor(.orange)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

struct TileDetailView: View {
    let tile: Tile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tile.ownerName ?? "Território neutro")
                        .font(.headline)
                    if let type = tile.ownerType {
                        Text(type == .bandeira ? "Bandeira" : "Solo")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2), in: Capsule())
                    }
                }
                Spacer()
                if let ownerColor = tile.ownerColor {
                    Circle()
                        .fill(Color(hex: ownerColor))
                        .frame(width: 18, height: 18)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Escudo")
                    Spacer()
                    Text("\(tile.shield)/100")
                        .bold()
                }
                ProgressView(value: Double(tile.shield), total: 100)
                    .tint(shieldColor(for: tile.shield))
            }

            if tile.isInDispute {
                Label("Tile em disputa", systemImage: "flame.fill")
                    .foregroundColor(.orange)
            }

            if tile.isInCooldown {
                Label("Em cooldown", systemImage: "lock.fill")
                    .foregroundColor(.blue)
            }

            if let guardian = tile.guardianName {
                Label("Guardião: \(guardian)", systemImage: "shield.lefthalf.fill")
            }

            Spacer()
        }
        .padding()
    }

    private func shieldColor(for value: Int) -> Color {
        switch value {
        case 70...:
            return .green
        case 40..<70:
            return .orange
        default:
            return .red
        }
    }
}
