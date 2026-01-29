import CoreLocation

enum GeoUtils {
    static func isPoint(_ point: CLLocationCoordinate2D, inside polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }

        if isPointOnBoundary(point, polygon: polygon) {
            return true
        }

        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let xi = polygon[i].longitude
            let yi = polygon[i].latitude
            let xj = polygon[j].longitude
            let yj = polygon[j].latitude

            let intersects = ((yi > point.latitude) != (yj > point.latitude))
                && (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi)

            if intersects {
                inside.toggle()
            }

            j = i
        }

        return inside
    }

    private static func isPointOnBoundary(_ point: CLLocationCoordinate2D,
                                          polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 2 else { return false }
        for i in 0..<polygon.count {
            let start = polygon[i]
            let end = polygon[(i + 1) % polygon.count]
            if isPoint(point, onSegmentBetween: start, and: end) {
                return true
            }
        }
        return false
    }

    private static func isPoint(_ point: CLLocationCoordinate2D,
                                onSegmentBetween start: CLLocationCoordinate2D,
                                and end: CLLocationCoordinate2D) -> Bool {
        let epsilon = 1e-9
        let cross = (point.latitude - start.latitude) * (end.longitude - start.longitude)
            - (point.longitude - start.longitude) * (end.latitude - start.latitude)
        if abs(cross) > epsilon {
            return false
        }

        let minLat = min(start.latitude, end.latitude) - epsilon
        let maxLat = max(start.latitude, end.latitude) + epsilon
        let minLon = min(start.longitude, end.longitude) - epsilon
        let maxLon = max(start.longitude, end.longitude) + epsilon

        return point.latitude >= minLat
            && point.latitude <= maxLat
            && point.longitude >= minLon
            && point.longitude <= maxLon
    }
}
