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

    // MARK: - Edge Cases

    func testEmptyPolygonReturnsFalse() {
        let polygon: [CLLocationCoordinate2D] = []
        let point = CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5)

        XCTAssertFalse(GeoUtils.isPoint(point, inside: polygon))
    }

    func testPolygonWithOneVertexReturnsFalse() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0)
        ]
        let point = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        XCTAssertFalse(GeoUtils.isPoint(point, inside: polygon))
    }

    func testPolygonWithTwoVerticesReturnsFalse() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 1, longitude: 1)
        ]
        let point = CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5)

        XCTAssertFalse(GeoUtils.isPoint(point, inside: polygon))
    }

    func testTrianglePolygon() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 2),
            CLLocationCoordinate2D(latitude: 2, longitude: 1)
        ]
        let insidePoint = CLLocationCoordinate2D(latitude: 0.5, longitude: 1)
        let outsidePoint = CLLocationCoordinate2D(latitude: 1.5, longitude: 0.5)

        XCTAssertTrue(GeoUtils.isPoint(insidePoint, inside: polygon))
        XCTAssertFalse(GeoUtils.isPoint(outsidePoint, inside: polygon))
    }

    // MARK: - Concave Polygon Tests

    func testPointInsideConcavePolygon() {
        // L-shaped concave polygon
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 2),
            CLLocationCoordinate2D(latitude: 1, longitude: 2),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 2, longitude: 1),
            CLLocationCoordinate2D(latitude: 2, longitude: 0)
        ]
        let insidePoint = CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5)

        XCTAssertTrue(GeoUtils.isPoint(insidePoint, inside: polygon))
    }

    func testPointInConcavityReturnsFalse() {
        // L-shaped concave polygon
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 2),
            CLLocationCoordinate2D(latitude: 1, longitude: 2),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 2, longitude: 1),
            CLLocationCoordinate2D(latitude: 2, longitude: 0)
        ]
        // Point in the concave "notch" area
        let pointInConcavity = CLLocationCoordinate2D(latitude: 1.5, longitude: 1.5)

        XCTAssertFalse(GeoUtils.isPoint(pointInConcavity, inside: polygon))
    }

    // MARK: - Boundary and Vertex Tests

    func testPointOnVertexBehavior() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 0)
        ]
        let pointOnVertex = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        // Points on vertices are considered inside via boundary check
        XCTAssertTrue(GeoUtils.isPoint(pointOnVertex, inside: polygon))
    }

    func testPointOnEdgeBehavior() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 0)
        ]
        let pointOnEdge = CLLocationCoordinate2D(latitude: 0, longitude: 0.5)

        // Points on edges are considered inside via boundary check
        XCTAssertTrue(GeoUtils.isPoint(pointOnEdge, inside: polygon))
    }

    // MARK: - Self-Intersecting Polygon Tests

    func testSelfIntersectingPolygonFigureEight() {
        // Figure-8 shaped self-intersecting polygon
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 2),
            CLLocationCoordinate2D(latitude: 2, longitude: 0),
            CLLocationCoordinate2D(latitude: 2, longitude: 2)
        ]
        let centerPoint = CLLocationCoordinate2D(latitude: 1, longitude: 1)

        // Self-intersecting polygons may produce unexpected results
        // This test documents the behavior at the intersection center
        _ = GeoUtils.isPoint(centerPoint, inside: polygon)
    }

    // MARK: - Additional Coverage Tests

    func testPointFarOutsidePolygon() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 0)
        ]
        let farPoint = CLLocationCoordinate2D(latitude: 100, longitude: 100)

        XCTAssertFalse(GeoUtils.isPoint(farPoint, inside: polygon))
    }

    func testPointWithNegativeCoordinates() {
        let polygon = [
            CLLocationCoordinate2D(latitude: -1, longitude: -1),
            CLLocationCoordinate2D(latitude: -1, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: -1)
        ]
        let insidePoint = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let outsidePoint = CLLocationCoordinate2D(latitude: -2, longitude: 0)

        XCTAssertTrue(GeoUtils.isPoint(insidePoint, inside: polygon))
        XCTAssertFalse(GeoUtils.isPoint(outsidePoint, inside: polygon))
    }

    func testIrregularPolygon() {
        // Pentagon-like irregular polygon
        let polygon = [
            CLLocationCoordinate2D(latitude: 0, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 2),
            CLLocationCoordinate2D(latitude: 2, longitude: 1.5),
            CLLocationCoordinate2D(latitude: 2, longitude: 0.5),
            CLLocationCoordinate2D(latitude: 1, longitude: 0)
        ]
        let insidePoint = CLLocationCoordinate2D(latitude: 1, longitude: 1)
        let outsidePoint = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        XCTAssertTrue(GeoUtils.isPoint(insidePoint, inside: polygon))
        XCTAssertFalse(GeoUtils.isPoint(outsidePoint, inside: polygon))
    }
}
