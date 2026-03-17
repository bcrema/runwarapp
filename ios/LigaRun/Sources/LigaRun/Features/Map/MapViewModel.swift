import Foundation
import CoreLocation

struct QuadraStateSummary: Equatable {
    let neutral: Int
    let owned: Int
    let disputed: Int
}

struct MapEmptyState: Equatable {
    let title: String
    let message: String
}

@MainActor
final class MapViewModel: ObservableObject {
    @Published var quadras: [Quadra] = []
    @Published var selectedQuadra: Quadra?
    @Published var focusCoordinate: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var activeFilter: MapOwnershipFilter = .all
    @Published private(set) var emptyState: MapEmptyState?
    @Published private(set) var contextualMessage: String?

    private let api: MapAPIProviding
    private let currentUserProvider: () -> User?
    private var lastVisibleBounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)?

    init(session: SessionStore, api: MapAPIProviding? = nil) {
        self.api = api ?? session.api
        self.currentUserProvider = { session.currentUser }
    }

    var quadraStateSummary: QuadraStateSummary {
        let counts = quadras.reduce(into: (neutral: 0, owned: 0, disputed: 0)) { result, quadra in
            if quadra.isInDispute {
                result.disputed += 1
            } else if quadra.ownerType != nil {
                result.owned += 1
            } else {
                result.neutral += 1
            }
        }
        return QuadraStateSummary(neutral: counts.neutral, owned: counts.owned, disputed: counts.disputed)
    }

    func updateVisibleBounds(
        _ bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double),
        filter: MapOwnershipFilter,
        focusContext: MapFocusContext? = nil
    ) async {
        lastVisibleBounds = bounds
        guard filter == .all else { return }
        await selectFilter(filter, focusContext: focusContext)
    }

    func selectFilter(_ filter: MapOwnershipFilter, focusContext: MapFocusContext? = nil) async {
        activeFilter = filter
        isLoading = true
        errorMessage = nil
        emptyState = nil
        contextualMessage = contextualMessage(for: filter, focusContext: focusContext)
        defer { isLoading = false }

        do {
            quadras = try await loadQuadras(for: filter, focusContext: focusContext)
            emptyState = quadras.isEmpty ? makeEmptyState(for: filter, focusContext: focusContext) : nil
        } catch {
            quadras = []
            errorMessage = mapErrorMessage(for: error)
        }
    }

    func refreshVisibleQuadras() async {
        guard let lastVisibleBounds else { return }
        await updateVisibleBounds(lastVisibleBounds, filter: activeFilter)
    }

    func refreshDisputedQuadras() async {
        await selectFilter(.disputed)
    }

    func focusOnQuadra(id: String) async {
        do {
            let quadra = try await api.getQuadra(id: id)
            focusCoordinate = CLLocationCoordinate2D(latitude: quadra.lat, longitude: quadra.lng)
            upsert(quadra: quadra)
        } catch {
            errorMessage = mapErrorMessage(for: error)
        }
    }

    private func loadQuadras(
        for filter: MapOwnershipFilter,
        focusContext: MapFocusContext?
    ) async throws -> [Quadra] {
        switch filter {
        case .all:
            guard let lastVisibleBounds else { return quadras }
            return try await api.getQuadras(bounds: lastVisibleBounds)
        case .disputed:
            return try await api.getDisputedQuadras()
        case .mine:
            guard let userId = resolvedUserId(from: focusContext) else {
                return []
            }
            return try await api.getQuadrasByUser(userId: userId)
        case .myBandeira:
            guard let bandeiraId = resolvedBandeiraId(from: focusContext) else {
                return []
            }
            return try await api.getQuadrasByBandeira(bandeiraId: bandeiraId)
        }
    }

    private func resolvedUserId(from focusContext: MapFocusContext?) -> String? {
        if case let .user(userId) = focusContext {
            return userId
        }
        return currentUserProvider()?.id
    }

    private func resolvedBandeiraId(from focusContext: MapFocusContext?) -> String? {
        if case let .bandeira(bandeiraId) = focusContext {
            return bandeiraId
        }
        return currentUserProvider()?.bandeiraId
    }

    private func makeEmptyState(
        for filter: MapOwnershipFilter,
        focusContext: MapFocusContext?
    ) -> MapEmptyState {
        switch filter {
        case .all:
            return MapEmptyState(
                title: "Nenhuma quadra visivel",
                message: "Mova o mapa para outra regiao ou aproxime a camera para carregar novas quadras."
            )
        case .disputed:
            return MapEmptyState(
                title: "Nenhuma disputa agora",
                message: "Nao ha quadras em disputa no momento. Tente novamente em instantes ou volte para Todas."
            )
        case .mine:
            if resolvedUserId(from: focusContext) == nil {
                return MapEmptyState(
                    title: "Sessao necessaria",
                    message: "Entre com sua conta para ver apenas as quadras sob seu controle."
                )
            }
            return MapEmptyState(
                title: "Voce ainda nao domina quadras",
                message: "Quando conquistar territorio, suas quadras aparecerao aqui sem mudar a camera."
            )
        case .myBandeira:
            if resolvedBandeiraId(from: focusContext) == nil {
                return MapEmptyState(
                    title: "Voce ainda nao tem bandeira",
                    message: "Entre em uma bandeira no hub social para liberar esse filtro e acompanhar o territorio coletivo."
                )
            }
            return MapEmptyState(
                title: "Nenhuma quadra dessa bandeira",
                message: "A bandeira filtrada ainda nao domina quadras nessa visao. Troque o filtro ou volte para Todas."
            )
        }
    }

    private func contextualMessage(
        for filter: MapOwnershipFilter,
        focusContext: MapFocusContext?
    ) -> String? {
        guard let currentUser = currentUserProvider() else { return nil }

        switch (filter, focusContext) {
        case let (.mine, .user(userId)) where userId != currentUser.id:
            return "Exibindo as quadras do corredor selecionado no fluxo social."
        case let (.myBandeira, .bandeira(bandeiraId)) where bandeiraId != currentUser.bandeiraId:
            return "Exibindo o territorio da bandeira selecionada no hub social."
        case (.myBandeira, _) where currentUser.bandeiraId == nil:
            return "Sem bandeira ativa: o filtro mostra um estado orientativo em vez de erro seco."
        default:
            return nil
        }
    }

    private func mapErrorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .badServerResponse:
                return "Serviço de mapa indisponível no momento. Tente novamente em instantes."
            case .timedOut:
                return "A requisição demorou demais. Tente novamente em instantes."
            case .notConnectedToInternet:
                return "Sem conexão com a internet. Verifique sua rede e tente novamente."
            default:
                break
            }
        }

        return "Não foi possível carregar o mapa agora. Tente novamente."
    }

    private func upsert(quadra: Quadra) {
        if let existingIndex = quadras.firstIndex(where: { $0.id == quadra.id }) {
            quadras[existingIndex] = quadra
            return
        }
        quadras.insert(quadra, at: 0)
    }
}
