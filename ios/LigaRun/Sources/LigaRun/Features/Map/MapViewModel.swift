import Foundation
import CoreLocation

struct TileStateSummary: Equatable {
    let neutral: Int
    let owned: Int
    let disputed: Int
}

@MainActor
final class MapViewModel: ObservableObject {
    @Published var tiles: [Tile] = []
    @Published var selectedTile: Tile?
    @Published var focusCoordinate: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: MapAPIProviding
    private var lastVisibleBounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)?

    init(session: SessionStore, api: MapAPIProviding? = nil) {
        self.api = api ?? session.api
    }

    var tileStateSummary: TileStateSummary {
        let counts = tiles.reduce(into: (neutral: 0, owned: 0, disputed: 0)) { result, tile in
            if tile.isInDispute {
                result.disputed += 1
            } else if tile.ownerType != nil {
                result.owned += 1
            } else {
                result.neutral += 1
            }
        }
        return TileStateSummary(neutral: counts.neutral, owned: counts.owned, disputed: counts.disputed)
    }

    func loadTiles(bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tiles = try await api.getTiles(bounds: bounds)
            lastVisibleBounds = bounds
        } catch {
            errorMessage = mapErrorMessage(for: error)
        }
    }

    func refreshVisibleTiles() async {
        guard let lastVisibleBounds else { return }
        await loadTiles(bounds: lastVisibleBounds)
    }

    func refreshDisputed() async {
        do {
            tiles = try await api.getDisputedTiles()
        } catch {
            errorMessage = mapErrorMessage(for: error)
        }
    }

    func focusOnTile(id: String) async {
        do {
            let tile = try await api.getTile(id: id)
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

    private func upsert(tile: Tile) {
        if let existingIndex = tiles.firstIndex(where: { $0.id == tile.id }) {
            tiles[existingIndex] = tile
            return
        }
        tiles.insert(tile, at: 0)
    }
}
