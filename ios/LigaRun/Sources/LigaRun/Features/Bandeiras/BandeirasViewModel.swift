import Foundation

@MainActor
final class BandeirasViewModel: ObservableObject {
    @Published var bandeiras: [Bandeira] = []
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: BandeirasAPIProviding
    private let refreshUserAction: () async throws -> Void

    init(
        session: SessionStore,
        api: BandeirasAPIProviding? = nil,
        refreshUser: (() async throws -> Void)? = nil
    ) {
        self.api = api ?? session.api
        refreshUserAction = refreshUser ?? { try await session.refreshUser() }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            bandeiras = try await api.getBandeiras()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func search() async {
        guard !searchQuery.isEmpty else {
            await load()
            return
        }

        do {
            bandeiras = try await api.searchBandeiras(query: searchQuery)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(name: String, category: String, color: String, description: String? = nil) async {
        do {
            _ = try await api.createBandeira(
                request: CreateBandeiraRequest(
                    name: name,
                    category: category,
                    color: color,
                    description: description
                )
            )
            await load()
            try? await refreshUserAction()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func join(bandeira: Bandeira) async {
        do {
            _ = try await api.joinBandeira(id: bandeira.id)
            await load()
            try? await refreshUserAction()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leave() async {
        do {
            try await api.leaveBandeira()
            try? await refreshUserAction()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
