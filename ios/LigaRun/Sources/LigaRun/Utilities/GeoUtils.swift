import CoreLocation

enum GeoUtils {
    static func isPoint(_ point: CLLocationCoordinate2D, inside polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }

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
}
