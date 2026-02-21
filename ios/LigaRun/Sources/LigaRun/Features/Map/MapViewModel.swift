import Foundation
import CoreLocation

struct QuadraStateSummary: Equatable {
    let neutral: Int
    let owned: Int
    let disputed: Int
}

@MainActor
final class MapViewModel: ObservableObject {
    @Published var quadras: [Quadra] = []
    @Published var selectedQuadra: Quadra?
    @Published var focusCoordinate: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: MapAPIProviding
    private var lastVisibleBounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)?

    init(session: SessionStore, api: MapAPIProviding? = nil) {
        self.api = api ?? session.api
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

    func loadQuadras(bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tiles = try await api.getQuadras(bounds: bounds)
            lastVisibleBounds = bounds
        } catch {
            errorMessage = mapErrorMessage(for: error)
        }
    }

    func refreshVisibleQuadras() async {
        guard let lastVisibleBounds else { return }
        await loadQuadras(bounds: lastVisibleBounds)
    }

    func refreshDisputedQuadras() async {
        do {
            tiles = try await api.getDisputedQuadras()
        } catch {
            errorMessage = mapErrorMessage(for: error)
        }
    }

    func focusOnQuadra(id: String) async {
        do {
            let tile = try await api.getQuadra(id: id)
            focusCoordinate = CLLocationCoordinate2D(latitude: tile.lat, longitude: tile.lng)
            upsert(tile: tile)
        } catch {
            errorMessage = mapErrorMessage(for: error)
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
