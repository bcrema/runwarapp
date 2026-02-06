import SwiftUI

struct ProfileStats: Equatable {
    let totalRuns: Int
    let totalDistance: Double
    let totalTilesConquered: Int

    static func from(user: User?) -> ProfileStats {
        guard let user else {
            return ProfileStats(totalRuns: 0, totalDistance: 0, totalTilesConquered: 0)
        }
        return ProfileStats(
            totalRuns: user.totalRuns,
            totalDistance: user.totalDistance,
            totalTilesConquered: user.totalTilesConquered
        )
    }
}

enum ProfileHistoryState: Equatable {
    case idle
    case loading
    case empty
    case loaded
    case failed(String)
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var recentRuns: [Run] = []
    @Published private(set) var historyState: ProfileHistoryState = .idle

    private let runService: RunServiceProtocol
    private let historyLimit: Int

    init(session: SessionStore, runService: RunServiceProtocol? = nil, historyLimit: Int = 10) {
        self.runService = runService ?? RunService(apiClient: session.api)
        self.historyLimit = historyLimit
    }

    func stats(for user: User?) -> ProfileStats {
        ProfileStats.from(user: user)
    }

    func loadRecentRuns() async {
        historyState = .loading

        do {
            let runs = try await runService.getMyRuns()
            recentRuns = Array(runs.prefix(historyLimit))
            historyState = recentRuns.isEmpty ? .empty : .loaded
        } catch {
            recentRuns = []
            if let apiError = error as? APIError {
                historyState = .failed(apiError.message)
            } else {
                historyState = .failed(error.localizedDescription)
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel: ProfileViewModel
    @State private var username: String = ""
    @State private var isPublic: Bool = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(session: SessionStore) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(session: session))
    }

    var body: some View {
        navigationContainer {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        Form {
            if let user = session.currentUser {
                Section("Stats básicas") {
                    ProfileStatsSection(stats: viewModel.stats(for: user))
                }

                Section("Histórico recente") {
                    historyContent
                }

                Section("Conta") {
                    Text(user.email)
                    TextField("Nome de usuário", text: $username)
                    Toggle("Perfil público", isOn: $isPublic)
                }
            } else {
                ProgressView("Carregando perfil...")
            }

            Section {
                Button("Salvar alterações") {
                    Task { await save() }
                }
                .disabled(isSaving)

                Button("Sair", role: .destructive) {
                    session.logout()
                }
            }
        }
        .navigationTitle("Perfil")
        .task {
            await loadProfileData()
        }
        .refreshable {
            await loadProfileData()
        }
        .alert("Erro", isPresented: Binding(get: {
            errorMessage != nil
        }, set: { newValue in
            if !newValue { errorMessage = nil }
        })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var historyContent: some View {
        switch viewModel.historyState {
        case .idle, .loading:
            ProgressView("Carregando corridas...")
        case .empty:
            Text("Você ainda não tem corridas com impacto territorial.")
                .foregroundColor(.secondary)
        case .failed(let message):
            Text("Não foi possível carregar o histórico: \(message)")
                .foregroundColor(.secondary)
        case .loaded:
            ForEach(viewModel.recentRuns) { run in
                ProfileHistoryRow(run: run)
            }
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

    @MainActor
    private func loadProfileData() async {
        if session.currentUser == nil {
            try? await session.refreshUser()
        }
        guard let user = session.currentUser else {
            return
        }
        username = user.username
        isPublic = user.isPublic
        await viewModel.loadRecentRuns()
    }

    @MainActor
    private func save() async {
        guard !username.isEmpty else {
            errorMessage = "Nome de usuário não pode ser vazio."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await session.updateProfile(request: UpdateProfileRequest(username: username, avatarUrl: nil, isPublic: isPublic))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ProfileStatsSection: View {
    let stats: ProfileStats

    var body: some View {
        HStack(spacing: 8) {
            statCard(title: "Corridas", value: "\(stats.totalRuns)")
            statCard(title: "Distância", value: String(format: "%.1f km", stats.totalDistance))
            statCard(title: "Tiles", value: "\(stats.totalTilesConquered)")
        }
        .padding(.vertical, 4)
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ProfileHistoryRow: View {
    let run: Run

    private var statusLabel: String {
        run.isValidForTerritory ? "Válido" : "Inválido"
    }

    private var statusColor: Color {
        run.isValidForTerritory ? .green : .red
    }

    private var actionLabel: String {
        guard let action = run.territoryAction?.uppercased() else {
            return "Ação territorial: sem efeito"
        }
        switch action {
        case "CONQUEST":
            return "Ação territorial: conquista"
        case "ATTACK":
            return "Ação territorial: ataque"
        case "DEFENSE":
            return "Ação territorial: defesa"
        default:
            return "Ação territorial: \(action.lowercased())"
        }
    }

    private var formattedStartTime: String {
        guard let date = Self.inputFormatter.date(from: run.startTime) else {
            return run.startTime
        }
        return Self.outputFormatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(format: "%.2f km", run.distance))
                    .font(.headline)
                Spacer()
                Text(statusLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(statusColor)
            }

            Text(actionLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Início: \(formattedStartTime)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private static let inputFormatter = ISO8601DateFormatter()
    private static let outputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
