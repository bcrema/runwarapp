import Foundation

@MainActor
protocol BandeirasServiceProtocol {
    func getBandeiras() async throws -> [Bandeira]
    func searchBandeiras(query: String) async throws -> [Bandeira]
    func createBandeira(request: CreateBandeiraRequest) async throws -> Bandeira
    func joinBandeira(id: String) async throws -> Bandeira
    func leaveBandeira() async throws
}

@MainActor
final class BandeirasService: BandeirasServiceProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getBandeiras() async throws -> [Bandeira] {
        try await apiClient.getBandeiras()
    }

    func searchBandeiras(query: String) async throws -> [Bandeira] {
        try await apiClient.searchBandeiras(query: query)
    }

    func createBandeira(request: CreateBandeiraRequest) async throws -> Bandeira {
        try await apiClient.createBandeira(request: request)
    }

    func joinBandeira(id: String) async throws -> Bandeira {
        try await apiClient.joinBandeira(id: id)
    }

    func leaveBandeira() async throws {
        try await apiClient.leaveBandeira()
    }
}

@MainActor
final class BandeirasViewModel: ObservableObject {
    @Published var bandeiras: [Bandeira] = []
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var isMutating = false
    @Published var isCreating = false
    @Published var actionBandeiraId: String?
    @Published var errorMessage: String?
    @Published var noticeMessage: String?
    @Published var createName: String = ""
    @Published var createCategory: String = ""
    @Published var createColor: String = "#22C55E"
    @Published var createDescription: String = ""
    @Published private(set) var currentBandeiraId: String?

    private let service: BandeirasServiceProtocol
    private let currentUserProvider: () -> User?
    private let refreshUserAction: () async throws -> Void

    init(
        session: SessionStore,
        service: BandeirasServiceProtocol? = nil
    ) {
        self.service = service ?? BandeirasService(apiClient: session.api)
        self.currentUserProvider = { session.currentUser }
        self.refreshUserAction = { try await session.refreshUser() }
        self.currentBandeiraId = session.currentUser?.bandeiraId
    }

    init(
        service: BandeirasServiceProtocol,
        currentUserProvider: @escaping () -> User?,
        refreshUserAction: @escaping () async throws -> Void
    ) {
        self.service = service
        self.currentUserProvider = currentUserProvider
        self.refreshUserAction = refreshUserAction
        self.currentBandeiraId = currentUserProvider()?.bandeiraId
    }

    var hasActiveSearch: Bool {
        !normalized(searchQuery).isEmpty
    }

    var shouldShowEmptyState: Bool {
        !isLoading && bandeiras.isEmpty
    }

    var emptyStateTitle: String {
        hasActiveSearch ? "Nenhuma bandeira encontrada" : "Nenhuma bandeira disponivel"
    }

    var emptyStateMessage: String {
        if hasActiveSearch {
            return "Tente outro termo de busca ou limpe o filtro para ver todas as bandeiras."
        }
        return "Ainda nao ha bandeiras cadastradas. Voce pode criar a primeira agora."
    }

    func load(syncFromSession: Bool = true) async {
        if syncFromSession {
            syncCurrentBandeiraFromSession()
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            bandeiras = try await service.getBandeiras()
        } catch {
            errorMessage = makeUserFacingMessage(
                for: error,
                fallback: "Nao foi possivel carregar as bandeiras. Tente novamente."
            )
        }
    }

    func search() async {
        let query = normalized(searchQuery)
        guard !query.isEmpty else {
            await load()
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            bandeiras = try await service.searchBandeiras(query: query)
        } catch {
            errorMessage = makeUserFacingMessage(
                for: error,
                fallback: "Nao foi possivel buscar bandeiras. Tente novamente."
            )
        }
    }

    func clearSearch() async {
        searchQuery = ""
        await load()
    }

    func createBandeira() async {
        guard !isCreating else { return }
        errorMessage = nil
        noticeMessage = nil

        guard let request = validateCreateRequest() else { return }

        isCreating = true
        defer { isCreating = false }

        do {
            let created = try await service.createBandeira(request: request)
            createName = ""
            createCategory = ""
            createColor = "#22C55E"
            createDescription = ""
            searchQuery = ""

            let refreshed = await refreshUserState(fallbackBandeiraId: currentBandeiraId)
            await load(syncFromSession: refreshed)
            if !bandeiras.contains(where: { $0.id == created.id }) {
                bandeiras.insert(created, at: 0)
            }
            noticeMessage = "Bandeira \(created.name) criada com sucesso."
            if !refreshed {
                noticeMessage = "Bandeira \(created.name) criada com sucesso. Atualize para sincronizar sua sessao."
            }
        } catch {
            errorMessage = makeUserFacingMessage(
                for: error,
                fallback: "Nao foi possivel criar a bandeira. Revise os dados e tente novamente."
            )
        }
    }

    func join(bandeira: Bandeira) async {
        guard !isMutating else { return }
        errorMessage = nil
        noticeMessage = nil
        isMutating = true
        actionBandeiraId = bandeira.id
        defer {
            isMutating = false
            actionBandeiraId = nil
        }

        do {
            _ = try await service.joinBandeira(id: bandeira.id)
            currentBandeiraId = bandeira.id
            let refreshed = await refreshUserState(fallbackBandeiraId: bandeira.id)
            await load(syncFromSession: refreshed)
            noticeMessage = "Agora voce faz parte de \(bandeira.name). A partir da proxima corrida valida, suas acoes contam para a bandeira."
            if !refreshed {
                noticeMessage = "Agora voce faz parte de \(bandeira.name). Atualize para sincronizar sua sessao local."
            }
        } catch {
            errorMessage = makeUserFacingMessage(
                for: error,
                fallback: "Nao foi possivel entrar na bandeira. Tente novamente."
            )
        }
    }

    func leave() async {
        guard !isMutating else { return }
        errorMessage = nil
        noticeMessage = nil
        isMutating = true
        actionBandeiraId = currentBandeiraId
        defer {
            isMutating = false
            actionBandeiraId = nil
        }

        do {
            try await service.leaveBandeira()
            currentBandeiraId = nil
            let refreshed = await refreshUserState(fallbackBandeiraId: nil)
            await load(syncFromSession: refreshed)
            noticeMessage = "Voce saiu da bandeira. A partir da proxima corrida valida, as acoes voltam para sua conta."
            if !refreshed {
                noticeMessage = "Voce saiu da bandeira. Atualize para sincronizar sua sessao local."
            }
        } catch {
            errorMessage = makeUserFacingMessage(
                for: error,
                fallback: "Nao foi possivel sair da bandeira. Tente novamente."
            )
        }
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func syncCurrentBandeiraFromSession() {
        currentBandeiraId = currentUserProvider()?.bandeiraId
    }

    @discardableResult
    private func refreshUserState(fallbackBandeiraId: String?) async -> Bool {
        do {
            try await refreshUserAction()
            syncCurrentBandeiraFromSession()
            return true
        } catch {
            currentBandeiraId = fallbackBandeiraId
            return false
        }
    }

    private func validateCreateRequest() -> CreateBandeiraRequest? {
        let name = normalized(createName)
        if name.isEmpty {
            errorMessage = "Informe o nome da bandeira."
            return nil
        }

        let category = normalized(createCategory)
        if category.isEmpty {
            errorMessage = "Informe a categoria da bandeira."
            return nil
        }

        let rawColor = normalized(createColor).uppercased()
        let color = rawColor.hasPrefix("#") ? rawColor : "#\(rawColor)"
        if !isValidHexColor(color) {
            errorMessage = "Cor invalida. Use o formato #RRGGBB."
            return nil
        }

        let description = normalized(createDescription)
        return CreateBandeiraRequest(
            name: name,
            category: category,
            color: color,
            description: description.isEmpty ? nil : description
        )
    }

    private func isValidHexColor(_ color: String) -> Bool {
        guard color.count == 7, color.hasPrefix("#") else { return false }
        let hexDigits = color.dropFirst()
        return hexDigits.allSatisfy { $0.isHexDigit }
    }

    private func makeUserFacingMessage(for error: Error, fallback: String) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "Sem conexao com a internet. Verifique sua rede e tente novamente."
            case .timedOut:
                return "A requisicao demorou demais. Tente novamente em instantes."
            default:
                break
            }
        }

        return fallback
    }
}
