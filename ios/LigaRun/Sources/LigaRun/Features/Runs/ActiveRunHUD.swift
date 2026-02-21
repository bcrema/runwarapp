import SwiftUI
import CoreLocation
import MapboxMaps

struct ActiveRunHUD: View {
    @ObservedObject private var session: SessionStore
    @StateObject private var mapViewModel: MapViewModel
    @StateObject private var runManager: CompanionRunManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentQuadra: Tile?
    @State private var currentEligibility = QuadraEligibilityResult(status: .trainingOnly(reason: .missingQuadraOwnershipData))
    @State private var focusCoordinate: CLLocationCoordinate2D?
    @State private var lastFocusLocation: CLLocation?

    private let tealColor = Color(red: 0/255, green: 200/255, blue: 150/255)

    init(session: SessionStore) {
        self.session = session
        _mapViewModel = StateObject(wrappedValue: MapViewModel(session: session))

        let runSessionStore = RunSessionStore()
        let uploadService = RunUploadService(api: session.api, store: runSessionStore)
        let syncCoordinator = RunSyncCoordinator(
            runSessionStore: runSessionStore,
            uploadService: uploadService
        )
        _runManager = StateObject(
            wrappedValue: CompanionRunManager(
                locationManager: LocationManager(),
                syncCoordinator: syncCoordinator
            )
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            HexMapView(
                selectedQuadra: .constant(nil),
                quadras: mapViewModel.quadras,
                focusCoordinate: focusCoordinate,
                routeCoordinates: runManager.routeCoordinates,
                showsUserLocation: true,
                styleURI: .standard,
                onVisibleRegionChanged: { bounds in
                    Task { await mapViewModel.loadQuadras(bounds: bounds.toTuple) }
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    statusPill
                    Button {
                        handleCloseTapped()
                    } label: {
                        Image(systemName: closeButtonIcon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .disabled(isSyncInFlight)
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
            updateCurrentQuadraAndMode()
            updateFocusCoordinate()
        }
        .onChange(of: runManager.submissionResult?.id) { _ in
            guard let result = runManager.submissionResult else { return }
            session.pendingSubmissionResult = result
            session.selectedTabIndex = 1
            dismiss()
        }
        .onReceive(mapViewModel.$quadras) { _ in
            updateCurrentQuadraAndMode()
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

    private var closeButtonIcon: String {
        runManager.state == .idle ? "xmark" : "stop.fill"
    }

    private var isSyncInFlight: Bool {
        runManager.state == .idle && {
            switch runManager.syncState {
            case .waitingForSync, .uploading:
                return true
            default:
                return false
            }
        }()
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Image(systemName: syncStatus.icon)
                .foregroundColor(syncStatus.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(syncStatus.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(syncStatus.detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    private var syncStatus: (title: String, detail: String, color: Color, icon: String) {
        if runManager.state == .running {
            return (
                title: "Corrida em andamento",
                detail: runModeStatusText,
                color: statusAccentColor,
                icon: statusIcon
            )
        }

        if runManager.state == .paused {
            return (
                title: "Corrida pausada",
                detail: "Toque em continuar para retomar a rota.",
                color: .orange,
                icon: "pause.circle.fill"
            )
        }

        switch runManager.syncState {
        case .running:
            return (
                title: "Corrida pronta",
                detail: "Aguardando inicio da corrida.",
                color: tealColor,
                icon: "figure.run"
            )
        case .waitingForSync:
            return (
                title: "Aguardando sync",
                detail: "Encerrando corrida e preparando envio.",
                color: .secondary,
                icon: "arrow.triangle.2.circlepath.circle"
            )
        case .uploading:
            return (
                title: "Enviando corrida",
                detail: "Mantendo dados locais para retry em caso de falha.",
                color: .blue,
                icon: "arrow.up.circle.fill"
            )
        case .completed:
            return (
                title: "Sincronizacao concluida",
                detail: "Resultado pronto para o resumo pos-corrida.",
                color: .green,
                icon: "checkmark.circle.fill"
            )
        case .failed(let message):
            return (
                title: "Falha na sincronizacao",
                detail: message,
                color: .red,
                icon: "exclamationmark.triangle.fill"
            )
        }
    }

    private var runModeStatusText: String {
        guard let currentQuadra else {
            return "Modo treino • Fora de quadra carregada"
        }

        let owner = currentQuadra.ownerName ?? "Quadra neutra"
        let modeText = currentModeLabel
        var parts = ["\(modeText)", "\(owner)", "Escudo \(currentQuadra.shield)%"]
        if currentQuadra.isInDispute {
            parts.append("Em disputa")
        }
        if let message = ineligibilityMessage {
            parts.append(message)
        }
        return "Quadra #\(String(currentQuadra.id.prefix(6))) • " + parts.joined(separator: " • ")
    }

    private var currentModeLabel: String {
        switch currentEligibility.status {
        case .eligibleCompetitive:
            return "Modo competitivo"
        case .trainingOnly:
            return "Modo treino"
        }
    }

    private var ineligibilityMessage: String? {
        guard case let .trainingOnly(reason) = currentEligibility.status else {
            return nil
        }

        switch reason {
        case .missingUserContext:
            return "Bloqueio competitivo: sem usuário elegível"
        case .missingQuadraOwnershipData:
            return "Bloqueio competitivo: sem dados de posse"
        case .userNotOwnerNorChampion:
            return "Bloqueio competitivo: voce nao e dono/campeao"
        }
    }

    private var statusAccentColor: Color {
        if case .trainingOnly = currentEligibility.status {
            return .orange
        }
        return currentQuadra?.isInDispute == true ? .orange : tealColor
    }

    private var statusIcon: String {
        if case .trainingOnly = currentEligibility.status {
            return "figure.walk.motion"
        }
        return currentQuadra?.isInDispute == true ? "flame.fill" : "shield.fill"
    }

    private var statsCard: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            HStack(spacing: 32) {
                metricBlock(value: runManager.formattedDistance, label: "DISTANCIA")
                metricBlock(value: runManager.formattedPace, label: "PACE")
            }

            HStack(spacing: 40) {
                loopGauge
                runControls
            }

            syncFooter
                .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .background(Color(.systemBackground))
        .cornerRadius(32, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: -5)
    }

    private var loopGauge: some View {
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
    }

    @ViewBuilder
    private var runControls: some View {
        if runManager.state == .running || runManager.state == .paused {
            HStack(spacing: 12) {
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
                            .frame(width: 64, height: 64)
                            .shadow(color: (runManager.state == .running ? Color.black : tealColor).opacity(0.3), radius: 10, x: 0, y: 5)

                        Image(systemName: runManager.state == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Button(action: {
                    runManager.stopAndSync()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)

                        Image(systemName: "stop.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        } else {
            VStack(spacing: 10) {
                if case .failed = runManager.syncState {
                    Button("Tentar novamente") {
                        runManager.retrySync()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if case .completed = runManager.syncState {
                    Button("Fechar") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }

                if isSyncInFlight {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
    }

    @ViewBuilder
    private var syncFooter: some View {
        switch runManager.syncState {
        case .running:
            Text("Pause, continue e encerre quando finalizar seu loop.")
                .font(.footnote)
                .foregroundColor(.secondary)
        case .waitingForSync:
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text("Preparando sincronizacao da corrida...")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        case .uploading:
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text("Enviando corrida para o servidor...")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        case .completed:
            Text("Sincronizacao concluida. Abrindo resumo da corrida.")
                .font(.footnote)
                .foregroundColor(.green)
        case .failed(let message):
            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
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

    private func handleCloseTapped() {
        if runManager.state == .idle {
            dismiss()
            return
        }
        runManager.stopAndSync()
    }

    private func updateCurrentQuadraAndMode() {
        guard let location = runManager.currentLocation else {
            currentQuadra = nil
            currentEligibility = QuadraEligibilityResult(status: .trainingOnly(reason: .missingQuadraOwnershipData))
            runManager.updateRunModeContext(
                RunModeContext(mode: .treino, currentQuadraId: nil, ineligibilityReason: .missingQuadraOwnershipData)
            )
            return
        }

        currentQuadra = mapViewModel.quadras.first { quadra in
            GeoUtils.isPoint(location.coordinate, inside: quadra.boundaryCoordinates)
        }

        guard let currentQuadra else {
            currentEligibility = QuadraEligibilityResult(status: .trainingOnly(reason: .missingQuadraOwnershipData))
            runManager.updateRunModeContext(
                RunModeContext(mode: .treino, currentQuadraId: nil, ineligibilityReason: .missingQuadraOwnershipData)
            )
            return
        }

        let eligibility = QuadraEligibilityPolicy().evaluate(currentUser: session.currentUser, quadra: currentQuadra)
        currentEligibility = eligibility

        switch eligibility.status {
        case .eligibleCompetitive:
            runManager.updateRunModeContext(
                RunModeContext(mode: .competitivo, currentQuadraId: currentQuadra.id, ineligibilityReason: nil)
            )
        case .trainingOnly(let reason):
            runManager.updateRunModeContext(
                RunModeContext(mode: .treino, currentQuadraId: currentQuadra.id, ineligibilityReason: reason)
            )
        }
    }

    private func updateFocusCoordinate() {
        guard let location = runManager.currentLocation else { return }
        if lastFocusLocation == nil {
            lastFocusLocation = location
            focusCoordinate = location.coordinate
            return
        }
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
