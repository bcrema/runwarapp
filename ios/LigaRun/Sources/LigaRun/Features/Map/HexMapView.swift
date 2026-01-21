import SwiftUI
import MapboxMaps
import Turf

struct HexMapView: UIViewRepresentable {
    @Binding var selectedTile: Tile?
    var tiles: [Tile]
    var onVisibleRegionChanged: ((CoordinateBounds) -> Void)?
    var onTileTapped: ((Tile) -> Void)?

    func makeUIView(context: Context) -> MapView {
        MapboxOptions.accessToken = AppEnvironment.mapboxAccessToken
        let initOptions = MapInitOptions(
            cameraOptions: CameraOptions(
                center: CLLocationCoordinate2D(latitude: -25.43, longitude: -49.27),
                zoom: 13
            ),
            styleURI: .dark
        )
        let mapView = MapView(frame: .zero, mapInitOptions: initOptions)

        context.coordinator.bind(mapView: mapView)

        mapView.mapboxMap.onMapLoaded.observe { _ in
            context.coordinator.configureStyle()
        }

        mapView.mapboxMap.onMapIdle.observe { _ in
            let bounds = mapView.mapboxMap.coordinateBounds(for: mapView.bounds)
            onVisibleRegionChanged?(bounds)
        }

        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {
        context.coordinator.updateTiles(tiles)
        context.coordinator.onTileTapped = onTileTapped
        context.coordinator.selectedTile = selectedTile
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        private weak var mapView: MapView?
        var onTileTapped: ((Tile) -> Void)?
        var selectedTile: Tile?
        private var addedTapHandler = false

        func bind(mapView: MapView) {
            self.mapView = mapView
        }

        func configureStyle() {
            guard let mapView else { return }
            var source = GeoJSONSource(id: "hex-source")
            source.data = .featureCollection(.init(features: []))
            try? mapView.mapboxMap.style.addSource(source)

            var fillLayer = FillLayer(id: "hex-fill", source: "hex-source")
            fillLayer.fillColor = .expression(Exp(.get) { "fillColor" })
            fillLayer.fillOpacity = .expression(Exp(.get) { "fillOpacity" })
            try? mapView.mapboxMap.style.addLayer(fillLayer)

            var outline = LineLayer(id: "hex-outline", source: "hex-source")
            outline.lineColor = .expression(Exp(.get) { "strokeColor" })
            outline.lineWidth = .constant(1.0)
            outline.lineOpacity = .constant(0.6)
            try? mapView.mapboxMap.style.addLayer(outline)

            addTapHandlerIfNeeded()
        }

        func addTapHandlerIfNeeded() {
            guard let mapView, !addedTapHandler else { return }
            addedTapHandler = true

            mapView.gestures.onMapTap.observe { [weak self] context in
                guard let self = self else { return }
                let options = RenderedQueryOptions(layerIds: ["hex-fill"], filter: nil)
                mapView.mapboxMap.queryRenderedFeatures(with: context.point, options: options) { result in
                    guard case let .success(features) = result,
                          let feature = features.first?.queriedFeature.feature,
                          case let .string(id) = feature.identifier else { return }

                    if let tile = self.currentTiles.first(where: { $0.id == id }) {
                        self.onTileTapped?(tile)
                        self.selectedTile = tile
                    }
                }
            }
        }

        private var currentTiles: [Tile] = []

        func updateTiles(_ tiles: [Tile]) {
            currentTiles = tiles
            guard let mapView,
                  mapView.mapboxMap.style.sourceExists(withId: "hex-source")
            else { return }

            let features: [Feature] = tiles.map { tile in
                var coords = tile.boundaryCoordinates
                if let first = coords.first {
                    coords.append(first)
                }

                let ring = Ring(coordinates: coords.map { LocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
                let polygon = Polygon([ring.coordinates])
                var feature = Feature(geometry: polygon)
                feature.identifier = .string(tile.id)

                let fillColor = tile.ownerColor ?? "#6b7280"
                let strokeColor = tile.isInDispute ? "#f59e0b" : (tile.ownerColor ?? "#ffffff")
                let fillOpacity: Double = tile.ownerType == nil ? 0.1 : 0.4

                feature.properties = [
                    "fillColor": .string(fillColor),
                    "strokeColor": .string(strokeColor),
                    "fillOpacity": .number(fillOpacity)
                ]

                return feature
            }

            let collection = FeatureCollection(features: features)
            mapView.mapboxMap.style.updateGeoJSONSource(withId: "hex-source", geoJSON: .featureCollection(collection))
        }
    }
}
