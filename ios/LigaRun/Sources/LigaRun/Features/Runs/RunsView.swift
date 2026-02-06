import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct RunsView: View {
    @StateObject private var viewModel: RunsViewModel
    @StateObject private var healthKitStore = HealthKitAuthorizationStore()
    @State private var showingImporter = false
    @State private var showingActiveRun = false
    @EnvironmentObject private var session: SessionStore
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    init(session: SessionStore) {
        _viewModel = StateObject(wrappedValue: RunsViewModel(session: session))
    }

    var body: some View {
        navigationContainer {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        List {
            if healthKitStore.shouldShowPermissionCard {
                Section("Permissões") {
                    HealthKitPermissionCard(
                        availability: healthKitStore.availability,
                        status: healthKitStore.status,
                        onRequest: { healthKitStore.requestAuthorization() },
                        onOpenSettings: openSettings
                    )
                }
            }

            Section("Corrida") {
                Button {
                    showingActiveRun = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Acompanhar corrida")
                                .font(.headline)
                            Text("Abra o Fitness/Workout para iniciar. O LigaRun mostra o território em tempo real.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            if let status = viewModel.dailyStatus {
                Section("Ações diárias") {
                    HStack {
                        Text("Usuário")
                        Spacer()
                        Text("\(status.userActionsRemaining) restantes")
                            .bold()
                    }
                    if let bandeiraCap = status.bandeiraActionCap, let bandeiraUsed = status.bandeiraActionsUsed {
                        HStack {
                            Text("Bandeira")
                            Spacer()
                            Text("\(bandeiraCap - bandeiraUsed) restantes")
                                .bold()
                        }
                    }
                }
            }

            Section("Minhas corridas") {
                if viewModel.runs.isEmpty {
                    Text("Nenhuma corrida enviada ainda.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.runs) { run in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(run.distance, specifier: "%.2f") km")
                                    .font(.headline)
                                Spacer()
                                Text(run.isLoopValid ? "Válido" : "Inválido")
                                    .font(.caption)
                                    .foregroundColor(run.isLoopValid ? .green : .red)
                            }
                            if let action = run.territoryAction {
                                Text("Ação: \(action)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("Início: \(run.startTime)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Corridas")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingImporter = true
                } label: {
                    Label("Enviar GPX", systemImage: "square.and.arrow.up")
                }
            }
        }
        .refreshable { @MainActor in
            await viewModel.load()
        }
        .task { @MainActor in
            await viewModel.load()
        }
        .onAppear {
            Task { @MainActor in
                await healthKitStore.refreshStatus()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { @MainActor in
                    await healthKitStore.refreshStatus()
                }
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
        .sheet(item: Binding(
            get: { viewModel.submissionResult },
            set: { _ in viewModel.submissionResult = nil })
        ) { result in
            if #available(iOS 16, *) {
                SubmissionResultView(result: result)
                    .presentationDetents([.medium])
            } else {
                SubmissionResultView(result: result)
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [UTType(filenameExtension: "gpx") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task { @MainActor in
                        await viewModel.submitGPX(at: url)
                    }
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .fullScreenCover(isPresented: $showingActiveRun) {
            ActiveRunHUD(session: session)
        }
    }

    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if #available(iOS 16, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

private struct HealthKitPermissionCard: View {
    let availability: HealthKitAvailability
    let status: HealthKitAuthorizationState
    let onRequest: () -> Void
    let onOpenSettings: () -> Void

    private var statusLabel: String {
        switch availability {
        case .notAvailable:
            return "Indisponível"
        case .checking:
            return "Verificando"
        case .available:
            switch status {
            case .authorized:
                return "Concedido"
            case .denied:
                return "Negado"
            case .restricted:
                return "Restrito"
            case .notDetermined:
                return "Pendente"
            }
        }
    }

    private var statusColor: Color {
        switch availability {
        case .notAvailable:
            return .secondary
        case .checking:
            return .secondary
        case .available:
            switch status {
            case .authorized:
                return .green
            case .denied:
                return .red
            case .restricted:
                return .orange
            case .notDetermined:
                return .secondary
            }
        }
    }

    private var descriptionText: String {
        switch availability {
        case .notAvailable:
            return "O Saúde (HealthKit) não está disponível neste dispositivo."
        case .checking:
            return "Verificando disponibilidade do Saúde..."
        case .available:
            switch status {
            case .authorized:
                return "Acesso concedido. O LigaRun pode importar suas corridas automaticamente."
            case .notDetermined:
                return "Permita que o LigaRun leia suas corridas para importar automaticamente."
            case .denied, .restricted:
                return "A permissão foi negada, restrita ou não há corridas disponíveis no Saúde. Abra os Ajustes para permitir o acesso ao Saúde."
            }
        }
    }

    private var showsRequestButton: Bool {
        availability == .available && status == .notDetermined
    }

    private var showsSettingsButton: Bool {
        availability == .available && (status == .denied || status == .restricted)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Permitir acesso ao Saúde")
                    .font(.headline)
                Spacer()
                Text(statusLabel)
                    .font(.subheadline.bold())
                    .foregroundColor(statusColor)
            }

            Text(descriptionText)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if showsRequestButton {
                Button(action: onRequest) {
                    Text("Permitir acesso ao Saúde")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if showsSettingsButton {
                Button(action: onOpenSettings) {
                    Text("Abrir Ajustes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SubmissionResultView: View {
    let result: RunSubmissionResult
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    private var actionTypeLabel: String {
        let actionType = result.turnResult?.actionType ?? result.territoryResult?.actionType
        switch actionType {
        case "CONQUEST":
            return "🏴 Conquistou"
        case "ATTACK":
            return "⚔️ Atacou"
        case "DEFENSE":
            return "🛡️ Defendeu"
        default:
            return "😐 Sem efeito"
        }
    }

    private var tileFocusId: String? {
        result.turnResult?.tileId ?? result.territoryResult?.tileId ?? result.loopValidation.primaryTile
    }

    private var shieldBefore: String {
        if let value = result.turnResult?.shieldBefore {
            return "\(value)"
        }
        if let territory = result.territoryResult {
            return "\(territory.shieldBefore)"
        }
        return "—"
    }

    private var shieldAfter: String {
        if let value = result.turnResult?.shieldAfter {
            return "\(value)"
        }
        if let territory = result.territoryResult {
            return "\(territory.shieldAfter)"
        }
        return "—"
    }

    private var cooldownLabel: String {
        guard let cooldown = result.turnResult?.cooldownUntil else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        guard let date = ISO8601DateFormatter().date(from: cooldown) else {
            return cooldown
        }
        return formatter.string(from: date)
    }

    private var reasons: [String] {
        var output: [String] = []
        if let turnReasons = result.turnResult?.reasons {
            output.append(contentsOf: turnReasons)
        }
        output.append(contentsOf: result.loopValidation.failureReasons)
        output.append(contentsOf: result.loopValidation.fraudFlags.map { "fraud_flag:\($0)" })
        if let territoryReason = result.territoryResult?.reason {
            output.append(territoryReason)
        }
        return output.map { translateReason($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Resultado da corrida")
                    .font(.headline)

                Text(result.loopValidation.isValid ? "Loop válido" : "Loop inválido")
                    .foregroundColor(result.loopValidation.isValid ? .green : .red)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Tipo de ação")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(actionTypeLabel)
                            .font(.subheadline)
                    }
                    HStack {
                        Text("Tile afetado")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(tileFocusId ?? "—")
                            .font(.subheadline)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Escudo antes/depois")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(shieldBefore) → \(shieldAfter)")
                            .font(.subheadline)
                    }
                    HStack {
                        Text("Cooldown")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(cooldownLabel)
                            .font(.subheadline)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !reasons.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Por que não contou:")
                            .font(.subheadline.bold())
                        ForEach(reasons, id: \.self) { reason in
                            Text("• \(reason)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button {
                    guard let tileId = tileFocusId else { return }
                    session.mapFocusTileId = tileId
                    session.selectedTabIndex = 0
                    dismiss()
                } label: {
                    Text("Ver no mapa")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(tileFocusId == nil)

                Spacer()
            }
            .padding()
        }
    }
}

private func translateReason(_ reason: String) -> String {
    if reason.hasPrefix("fraud_flag:") {
        let flag = reason.replacingOccurrences(of: "fraud_flag:", with: "")
        return "Padrão suspeito detectado (\(flag))"
    }

    let translations: [String: String] = [
        "distance_too_short": "Distância muito curta (mínimo 1.2km)",
        "duration_too_short": "Duração muito curta (mínimo 7 minutos)",
        "loop_not_closed": "Loop não fechado (máximo 40m entre início e fim)",
        "insufficient_tile_coverage": "Cobertura insuficiente do tile (mínimo 60%)",
        "fraud_detected": "Padrão suspeito detectado",
        "outside_game_area": "Fora da área do jogo (Curitiba)",
        "no_primary_tile": "Não foi possível determinar um tile principal para essa corrida.",
        "user_daily_cap_reached": "Limite diário de ações atingido.",
        "bandeira_daily_cap_reached": "Limite diário de ações da bandeira atingido.",
        "cannot_determine_action": "Não foi possível determinar a ação (conquista/ataque/defesa).",
        "tile_already_owned": "Tile já possui dono.",
        "cannot_attack_neutral": "Não é possível atacar um tile neutro.",
        "cannot_attack_own_tile": "Não é possível atacar o próprio tile.",
        "tile_in_cooldown": "Tile em cooldown; ataque bloqueado no momento.",
        "cannot_defend_rival_tile": "Não é possível defender um tile que não é seu."
    ]
    return translations[reason] ?? reason
}
