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

    private var territoryImpact: SubmissionTerritoryImpact {
        submissionTerritoryImpact(for: result)
    }

    private var tileFocusId: String? {
        submissionTileFocusId(for: result)
    }

    private var reasons: [String] {
        submissionResultReasons(for: result)
    }

    private var impactColor: Color {
        switch territoryImpact {
        case .conquest:
            return .green
        case .attack:
            return .orange
        case .defense:
            return .blue
        case .noEffect:
            return .secondary
        }
    }

    private var impactIcon: String {
        switch territoryImpact {
        case .conquest:
            return "flag.fill"
        case .attack:
            return "flame.fill"
        case .defense:
            return "shield.fill"
        case .noEffect:
            return "figure.walk"
        }
    }

    private var impactSubtitle: String {
        if !result.loopValidation.isValid {
            return "Treino salvo sem efeito competitivo."
        }

        switch territoryImpact {
        case .conquest:
            return "A corrida conquistou um tile para sua conta/bandeira."
        case .attack:
            return "A corrida causou impacto ofensivo no tile alvo."
        case .defense:
            return "A corrida reforçou a defesa do tile alvo."
        case .noEffect:
            return "A corrida foi salva, mas não alterou território."
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                territoryCard
                metricsCard

                if !result.loopValidation.isValid || !reasons.isEmpty {
                    invalidReasonCard
                }

                actionButtons
            }
            .padding()
        }
    }

    private var territoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: impactIcon)
                    .foregroundColor(impactColor)
                Text(submissionTerritoryImpactTitle(for: territoryImpact))
                    .font(.headline)
                Spacer()
                Text(result.loopValidation.isValid ? "Loop válido" : "Loop inválido")
                    .font(.caption.bold())
                    .foregroundColor(result.loopValidation.isValid ? .green : .red)
            }

            Text(impactSubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let cooldown = result.turnResult?.cooldownUntil {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Cooldown: \(formattedCooldown(cooldown))")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var metricsCard: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 10) {
            metricCell(title: "Distância", value: String(format: "%.2f km", result.run.distance))
            metricCell(title: "Tempo", value: submissionRunDurationLabel(for: result))
            metricCell(title: "Tile foco", value: tileFocusId ?? "—")
            metricCell(title: "Escudo", value: submissionShieldDeltaLabel(for: result))
        }
    }

    private func metricCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var invalidReasonCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Treino salvo sem efeito competitivo")
                .font(.subheadline.bold())

            Text("Veja abaixo os motivos processados para esta submissão:")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(reasons, id: \.self) { reason in
                Text("• \(reason)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
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

            Button("Fechar") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
    }

    private func formattedCooldown(_ value: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        guard let date = ISO8601DateFormatter().date(from: value) else {
            return value
        }
        return formatter.string(from: date)
    }
}
