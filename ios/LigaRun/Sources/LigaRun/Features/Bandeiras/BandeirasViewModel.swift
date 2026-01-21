import Foundation

@MainActor
final class BandeirasViewModel: ObservableObject {
    @Published var bandeiras: [Bandeira] = []
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            bandeiras = try await session.api.getBandeiras()
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
            bandeiras = try await session.api.searchBandeiras(query: searchQuery)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func join(bandeira: Bandeira) async {
        do {
            _ = try await session.api.joinBandeira(id: bandeira.id)
            await load()
            try? await session.refreshUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leave() async {
        do {
            try await session.api.leaveBandeira()
            try? await session.refreshUser()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
