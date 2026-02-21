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
                selectedQuadra: $viewModel.selectedQuadra,
                quadras: viewModel.quadras,
                focusCoordinate: viewModel.focusCoordinate,
                onVisibleRegionChanged: { bounds in
                    Task { await viewModel.loadQuadras(bounds: bounds.toTuple) }
                },
                onQuadraTapped: { quadra in
                    viewModel.selectedQuadra = quadra
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    quadraStateLegend
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView("Carregando quadras...")
                                .padding(8)
                                .background(.ultraThinMaterial, in: Capsule())
                        }

                        Button {
                            Task { await viewModel.refreshDisputedQuadras() }
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
        .sheet(item: $viewModel.selectedQuadra) { quadra in
            if #available(iOS 16, *) {
                QuadraDetailView(quadra: quadra)
                    .presentationDetents([.fraction(0.4), .medium])
            } else {
                QuadraDetailView(quadra: quadra)
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
            guard let quadraId = newValue else { return }
            Task {
                await viewModel.refreshVisibleQuadras()
                await viewModel.focusOnQuadra(id: quadraId)
                session.mapFocusTileId = nil
            }
        }
        .onChange(of: session.selectedTabIndex) { newValue in
            guard newValue == 0 else { return }
            Task {
                await viewModel.refreshVisibleQuadras()
            }
        }
        .fullScreenCover(isPresented: $showingActiveRun) {
            ActiveRunHUD(session: session)
        }
    }

    private var quadraStateLegend: some View {
        let summary = viewModel.quadraStateSummary
        return VStack(alignment: .leading, spacing: 6) {
            Label("\(summary.neutral) \(summary.neutral == 1 ? "neutro" : "neutros")", systemImage: "circle.fill")
                .foregroundColor(.gray)
            Label("\(summary.owned) \(summary.owned == 1 ? "dominado" : "dominados")", systemImage: "shield.fill")
                .foregroundColor(.green)
            Label("\(summary.disputed) \(summary.disputed == 1 ? "disputa" : "disputas")", systemImage: "flame.fill")
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

struct QuadraDetailView: View {
    let quadra: Quadra

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quadra.ownerName ?? "Quadra neutra")
                        .font(.headline)
                    if let type = quadra.ownerType {
                        Text(type == .bandeira ? "Bandeira" : "Solo")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2), in: Capsule())
                    }
                }
                Spacer()
                if let ownerColor = quadra.ownerColor {
                    Circle()
                        .fill(Color(hex: ownerColor))
                        .frame(width: 18, height: 18)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Escudo")
                    Spacer()
                    Text("\(quadra.shield)/100")
                        .bold()
                }
                ProgressView(value: Double(quadra.shield), total: 100)
                    .tint(shieldColor(for: quadra.shield))
            }

            if quadra.isInDispute {
                Label("Quadra em disputa", systemImage: "flame.fill")
                    .foregroundColor(.orange)
            }

            if quadra.isInCooldown {
                Label("Em cooldown", systemImage: "lock.fill")
                    .foregroundColor(.blue)
            }

            if let guardian = quadra.guardianName {
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
