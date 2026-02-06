import SwiftUI
import MapboxMaps
import Turf

struct HexMapView: UIViewRepresentable {
    @Binding var selectedTile: Tile?
    var tiles: [Tile]
    var focusCoordinate: CLLocationCoordinate2D?
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var showsUserLocation: Bool = false
    var styleURI: StyleURI = .dark
    var onVisibleRegionChanged: ((CoordinateBounds) -> Void)?
    var onTileTapped: ((Tile) -> Void)?

    func makeUIView(context: Context) -> MapView {
        MapboxOptions.accessToken = AppEnvironment.mapboxAccessToken
        let initOptions = MapInitOptions(
            cameraOptions: CameraOptions(
                center: CLLocationCoordinate2D(latitude: -25.43, longitude: -49.27),
                zoom: 13
            ),
            styleURI: styleURI
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
        context.coordinator.showsUserLocation = showsUserLocation
        context.coordinator.updateUserLocationDisplay()
        context.coordinator.updateRoute(routeCoordinates)
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
        var showsUserLocation: Bool = false
        private var addedTapHandler = false
        private var cancellables: [Cancelable] = []
        private var isMapLoaded = false
        private var lastFocusedCoordinate: CLLocationCoordinate2D?
        private var pendingRouteCoordinates: [CLLocationCoordinate2D] = []

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

            var routeSource = GeoJSONSource(id: "route-source")
            routeSource.data = .featureCollection(.init(features: []))
            try? mapView.mapboxMap.addSource(routeSource)

            var routeLayer = LineLayer(id: "route-line", source: "route-source")
            routeLayer.lineColor = .constant(StyleColor("#34d399"))
            routeLayer.lineWidth = .constant(4.0)
            routeLayer.lineOpacity = .constant(0.9)
            routeLayer.lineCap = .constant(.round)
            routeLayer.lineJoin = .constant(.round)
            try? mapView.mapboxMap.addLayer(routeLayer)

            updateUserLocationDisplay()
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
                makePolygonFeature(for: tile)
            }

            let collection = FeatureCollection(features: features)
            let data = GeoJSONSourceData.featureCollection(collection)
            mapView.mapboxMap.updateGeoJSONSource(withId: "hex-source", data: data)
        }

        func updateRoute(_ coordinates: [CLLocationCoordinate2D]) {
            pendingRouteCoordinates = coordinates
            guard let mapView, isMapLoaded,
                  mapView.mapboxMap.sourceExists(withId: "route-source")
            else { return }

            let geoJSON: GeoJSONSourceData
            if coordinates.count >= 2 {
                let lineCoords = coordinates.map { LocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                let line = LineString(lineCoords)
                geoJSON = .feature(Feature(geometry: .lineString(line)))
            } else {
                geoJSON = .featureCollection(FeatureCollection(features: []))
            }

            mapView.mapboxMap.updateGeoJSONSource(withId: "route-source", data: geoJSON)
        }

        func updateUserLocationDisplay() {
            guard let mapView else { return }
            let status = CLLocationManager.authorizationStatus()
            let isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
            if showsUserLocation && isAuthorized {
                mapView.location.options.puckType = .puck2D()
                mapView.location.options.puckBearingEnabled = true
            } else {
                mapView.location.options.puckType = nil
                mapView.location.options.puckBearingEnabled = false
            }
        }

        private func setupObservers() {
            guard let mapView else { return }

            cancellables.append(
                mapView.mapboxMap.onMapLoaded.observeNext { [weak self] _ in
                    self?.configureStyle()
                    self?.isMapLoaded = true
                    self?.updateRoute(self?.pendingRouteCoordinates ?? [])
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

            let currentCenter = mapView.mapboxMap.cameraState.center
            if abs(currentCenter.latitude - coordinate.latitude) < 0.00001,
               abs(currentCenter.longitude - coordinate.longitude) < 0.00001 {
                return
            }

            lastFocusedCoordinate = coordinate
            let camera = CameraOptions(center: coordinate, zoom: 15)
            mapView.camera.ease(to: camera, duration: 0.8, curve: .easeInOut)
        }

        private func makePolygonFeature(for tile: Tile) -> Feature? {
            let coords = tile.boundaryCoordinates.map {
                LocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }

            guard coords.count >= 3, let first = coords.first else { return nil }

            var ring = coords
            if let last = ring.last,
               first.latitude != last.latitude || first.longitude != last.longitude {
                ring.append(first)
            }

            guard ring.count >= 4, abs(polygonArea(ring)) > 0.0000001 else { return nil }

            let polygon = Polygon([ring])
            var feature = Feature(geometry: .polygon(polygon))
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

        private func polygonArea(_ ring: [LocationCoordinate2D]) -> Double {
            guard ring.count >= 3 else { return 0 }
            var area = 0.0
            for index in 0..<(ring.count - 1) {
                let current = ring[index]
                let next = ring[index + 1]
                area += (current.longitude * next.latitude) - (next.longitude * current.latitude)
            }
            return area * 0.5
        }
    }
}
