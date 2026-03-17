import SwiftUI
import MapboxMaps

struct MapScreen: View {
    @ObservedObject private var session: SessionStore
    @StateObject private var viewModel: MapViewModel
    @State private var showingActiveRun = false
    @State private var pendingFocusContext: MapFocusContext?

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
                    Task {
                        await viewModel.updateVisibleBounds(
                            bounds.toTuple,
                            filter: session.activeMapOwnershipFilter,
                            focusContext: session.mapFocusContext
                        )
                    }
                },
                onQuadraTapped: { quadra in
                    viewModel.selectedQuadra = quadra
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    mapFilterBar

                    HStack(alignment: .top) {
                        quadraStateLegend
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView("Carregando quadras...")
                                .padding(8)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                if let contextualMessage = viewModel.contextualMessage {
                    inlineMessageCard(
                        title: "Contexto do mapa",
                        message: contextualMessage,
                        systemImage: "scope"
                    )
                    .padding(.horizontal)
                }

                if let emptyState = viewModel.emptyState {
                    inlineMessageCard(
                        title: emptyState.title,
                        message: emptyState.message,
                        systemImage: "map"
                    )
                    .padding(.horizontal)
                }

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
        .task {
            await applySharedMapState()
        }
        .onChange(of: session.activeMapOwnershipFilter) { _ in
            Task {
                await viewModel.selectFilter(
                    session.activeMapOwnershipFilter,
                    focusContext: consumePendingFocusContext()
                )
            }
        }
        .onChange(of: session.mapFocusQuadraId) { newValue in
            guard let quadraId = newValue else { return }
            Task {
                await applySharedMapState()
                await viewModel.focusOnQuadra(id: quadraId)
                session.mapFocusQuadraId = nil
            }
        }
        .onChange(of: session.mapFocusContext) { newValue in
            guard newValue != nil, session.selectedTabIndex == 0 else { return }
            Task {
                await applySharedMapState()
            }
        }
        .onChange(of: session.selectedTabIndex) { newValue in
            guard newValue == 0 else { return }
            Task {
                await applySharedMapState()
            }
        }
        .fullScreenCover(isPresented: $showingActiveRun) {
            ActiveRunHUD(session: session)
        }
    }

    @MainActor
    private func applySharedMapState() async {
        let focusContext = session.mapFocusContext
        pendingFocusContext = focusContext
        session.mapFocusContext = nil

        if let focusContext, session.activeMapOwnershipFilter == .all {
            session.activeMapOwnershipFilter = defaultFilter(for: focusContext)
            return
        }

        await viewModel.selectFilter(
            session.activeMapOwnershipFilter,
            focusContext: consumePendingFocusContext()
        )
    }

    @MainActor
    private func consumePendingFocusContext() -> MapFocusContext? {
        let focusContext = pendingFocusContext
        pendingFocusContext = nil
        return focusContext
    }

    private func defaultFilter(for focusContext: MapFocusContext) -> MapOwnershipFilter {
        switch focusContext {
        case .user:
            return .mine
        case .bandeira:
            return .myBandeira
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

    private var mapFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MapOwnershipFilter.allCases, id: \.self) { filter in
                    let isSelected = session.activeMapOwnershipFilter == filter
                    Button {
                        session.activeMapOwnershipFilter = filter
                    } label: {
                        Label(filterTitle(for: filter), systemImage: filterIcon(for: filter))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .foregroundColor(isSelected ? .white : .primary)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected ? Color.accentColor : Color.white.opacity(0.18))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func inlineMessageCard(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.accentColor)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func filterTitle(for filter: MapOwnershipFilter) -> String {
        switch filter {
        case .all:
            return "Todas"
        case .disputed:
            return "Em disputa"
        case .mine:
            return "Minhas"
        case .myBandeira:
            return "Da minha bandeira"
        }
    }

    private func filterIcon(for filter: MapOwnershipFilter) -> String {
        switch filter {
        case .all:
            return "square.grid.2x2"
        case .disputed:
            return "flame.fill"
        case .mine:
            return "figure.run"
        case .myBandeira:
            return "flag.fill"
        }
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

            territoryDecisionCard

            VStack(alignment: .leading, spacing: 10) {
                detailRow(
                    title: "Estado territorial",
                    value: territorialStateLabel,
                    systemImage: territorialStateIcon,
                    tint: territorialStateColor
                )

                if let champion = quadra.championName {
                    detailRow(
                        title: "Campeao",
                        value: champion,
                        systemImage: "crown.fill",
                        tint: .yellow
                    )
                }

                if let guardian = quadra.guardianName {
                    detailRow(
                        title: "Guardiao",
                        value: guardian,
                        systemImage: "shield.lefthalf.fill",
                        tint: .blue
                    )
                }
            }

            Spacer()
        }
        .padding()
    }

    private var territoryDecisionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(decisionSummaryTitle)
                .font(.headline)
            Text(decisionSummaryMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func detailRow(
        title: String,
        value: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundColor(tint)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private var territorialStateLabel: String {
        if quadra.isInDispute {
            return "Em disputa"
        }
        if quadra.isInCooldown {
            return "Em cooldown"
        }
        if quadra.ownerType == nil {
            return "Neutra"
        }
        return "Dominada"
    }

    private var territorialStateIcon: String {
        if quadra.isInDispute {
            return "flame.fill"
        }
        if quadra.isInCooldown {
            return "lock.fill"
        }
        if quadra.ownerType == nil {
            return "circle.dotted"
        }
        return "shield.fill"
    }

    private var territorialStateColor: Color {
        if quadra.isInDispute {
            return .orange
        }
        if quadra.isInCooldown {
            return .blue
        }
        if quadra.ownerType == nil {
            return .gray
        }
        return .green
    }

    private var decisionSummaryTitle: String {
        if quadra.isInDispute {
            return "Disputa aberta"
        }
        if quadra.ownerType == nil {
            return "Janela de conquista"
        }
        if quadra.isInCooldown {
            return "Territorio protegido"
        }
        if quadra.shield < 40 {
            return "Defesa fragil"
        }
        return "Territorio estavel"
    }

    private var decisionSummaryMessage: String {
        if quadra.isInDispute {
            return "A quadra esta em disputa agora. Vale agir rapido para defender ou virar o controle."
        }
        if quadra.ownerType == nil {
            return "Sem dono atual. Boa oportunidade para conquistar territorio sem perder contexto da camera."
        }
        if quadra.isInCooldown {
            return "A quadra esta em cooldown. Planeje a proxima investida quando a janela territorial reabrir."
        }
        if quadra.shield < 40 {
            return "O escudo esta baixo e o dominio pode virar rapido. Se a quadra for estrategica, vale competir."
        }
        return "O dominio esta consolidado. Vale defender se o ponto for critico ou buscar alvos mais frageis no entorno."
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
