import SwiftUI
import MapboxMaps
import Turf

struct HexMapView: UIViewRepresentable {
    @Binding var selectedTile: Tile?
    var tiles: [Tile]
    var focusCoordinate: CLLocationCoordinate2D?
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

        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {
        context.coordinator.updateTiles(tiles)
        context.coordinator.onTileTapped = onTileTapped
        context.coordinator.selectedTile = selectedTile
        context.coordinator.onVisibleRegionChanged = onVisibleRegionChanged
        context.coordinator.focusCoordinate = focusCoordinate
        context.coordinator.updateFocusIfNeeded()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        private weak var mapView: MapView?
        var onTileTapped: ((Tile) -> Void)?
        var onVisibleRegionChanged: ((CoordinateBounds) -> Void)?
        var selectedTile: Tile?
        var focusCoordinate: CLLocationCoordinate2D?
        private var addedTapHandler = false
        private var cancellables: [Cancelable] = []
        private var isMapLoaded = false
        private var lastFocusedCoordinate: CLLocationCoordinate2D?

        func bind(mapView: MapView) {
            self.mapView = mapView
            setupObservers()
        }

        func configureStyle() {
            guard let mapView else { return }
            var source = GeoJSONSource(id: "hex-source")
            source.data = .featureCollection(.init(features: []))
            try? mapView.mapboxMap.addSource(source)

            var fillLayer = FillLayer(id: "hex-fill", source: "hex-source")
            fillLayer.fillColor = .expression(Exp(.get) { "fillColor" })
            fillLayer.fillOpacity = .expression(Exp(.get) { "fillOpacity" })
            try? mapView.mapboxMap.addLayer(fillLayer)

            var outline = LineLayer(id: "hex-outline", source: "hex-source")
            outline.lineColor = .expression(Exp(.get) { "strokeColor" })
            outline.lineWidth = .constant(1.0)
            outline.lineOpacity = .constant(0.6)
            try? mapView.mapboxMap.addLayer(outline)

            addTapHandlerIfNeeded()
        }

        func addTapHandlerIfNeeded() {
            guard let mapView, !addedTapHandler else { return }
            addedTapHandler = true

            let interaction = TapInteraction(.layer("hex-fill")) { [weak self] feature, _ in
                guard
                    let self,
                    let id = feature.id?.id,
                    let tile = self.currentTiles.first(where: { $0.id == id })
                else { return false }

                self.onTileTapped?(tile)
                self.selectedTile = tile
                return true
            }

            let tapCancelable = mapView.mapboxMap.addInteraction(interaction)
            cancellables.append(tapCancelable)
        }

        private var currentTiles: [Tile] = []

        func updateTiles(_ tiles: [Tile]) {
            currentTiles = tiles
            guard let mapView,
                  mapView.mapboxMap.sourceExists(withId: "hex-source")
            else { return }

            let features: [Feature] = tiles.compactMap { tile in
                var coords = tile.boundaryCoordinates

                // Ensure we have a valid closed ring for fill polygons.
                guard coords.count >= 3, let first = coords.first else {
                    return nil
                }
                if coords.last != first {
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
            mapView.mapboxMap.updateGeoJSONSource(withId: "hex-source", geoJSON: .featureCollection(collection))
        }

        private func setupObservers() {
            guard let mapView else { return }

            cancellables.append(
                mapView.mapboxMap.onMapLoaded.observeNext { [weak self] _ in
                    self?.configureStyle()
                    self?.isMapLoaded = true
                    self?.updateFocusIfNeeded()
                }
            )

            cancellables.append(
                mapView.mapboxMap.onMapIdle.observeNext { [weak self, weak mapView] _ in
                    guard let self, let mapView else { return }
                    let bounds = mapView.mapboxMap.coordinateBounds(for: mapView.bounds)
                    self.onVisibleRegionChanged?(bounds)
                }
            )
        }

        func updateFocusIfNeeded() {
            guard
                isMapLoaded,
                let mapView,
                let coordinate = focusCoordinate
            else { return }

            let currentCenter = mapView.cameraState.center
            if abs(currentCenter.latitude - coordinate.latitude) < 0.00001,
               abs(currentCenter.longitude - coordinate.longitude) < 0.00001 {
                return
            }

            lastFocusedCoordinate = coordinate
            let camera = CameraOptions(center: coordinate, zoom: 15)
            mapView.camera.ease(to: camera, duration: 0.8, curve: .easeInOut)
        }
    }
}
