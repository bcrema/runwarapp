import XCTest
import CoreLocation
@testable import LigaRun

final class GeoUtilsTests: XCTestCase {
    func testPointInsidePolygonReturnsTrue() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 0)
        ]
        let point = CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5)

        XCTAssertTrue(GeoUtils.isPoint(point, inside: polygon))
    }

    func testPointOutsidePolygonReturnsFalse() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 0)
        ]
        let point = CLLocationCoordinate2D(latitude: 1.5, longitude: 0.5)

        XCTAssertFalse(GeoUtils.isPoint(point, inside: polygon))
    }
}
