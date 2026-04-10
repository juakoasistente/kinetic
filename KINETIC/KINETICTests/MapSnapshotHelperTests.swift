import Testing
import CoreLocation
@testable import KINETIC

struct MapSnapshotHelperTests {

    // MARK: - normalizeCoordinates

    @Test func normalize_emptyArray() {
        let result = MapSnapshotHelper.normalizeCoordinates([])
        #expect(result.isEmpty)
    }

    @Test func normalize_singlePoint_returnsEmpty() {
        let coords = [CLLocationCoordinate2D(latitude: 41.0, longitude: 2.0)]
        let result = MapSnapshotHelper.normalizeCoordinates(coords)
        #expect(result.isEmpty)
    }

    @Test func normalize_twoPoints_rangeZeroToOne() {
        let coords = [
            CLLocationCoordinate2D(latitude: 40.0, longitude: 2.0),
            CLLocationCoordinate2D(latitude: 41.0, longitude: 3.0),
        ]
        let result = MapSnapshotHelper.normalizeCoordinates(coords)
        #expect(result.count == 2)

        for point in result {
            #expect(point.x >= 0 && point.x <= 1)
            #expect(point.y >= 0 && point.y <= 1)
        }
    }

    @Test func normalize_preservesPointOrder() {
        let coords = [
            CLLocationCoordinate2D(latitude: 40.0, longitude: 2.0),
            CLLocationCoordinate2D(latitude: 40.5, longitude: 2.5),
            CLLocationCoordinate2D(latitude: 41.0, longitude: 3.0),
        ]
        let result = MapSnapshotHelper.normalizeCoordinates(coords)
        #expect(result.count == 3)
        // First point should be bottom-left-ish, last top-right-ish
        // (y is inverted: higher lat = lower y)
        #expect(result[0].y > result[2].y) // lower lat = higher y
    }

    @Test func normalize_identicalPoints_returnsEmpty() {
        let coord = CLLocationCoordinate2D(latitude: 41.0, longitude: 2.0)
        let result = MapSnapshotHelper.normalizeCoordinates([coord, coord, coord])
        #expect(result.isEmpty)
    }

    @Test func normalize_verticalLine_centeredHorizontally() {
        // Pure north-south line: longitude is constant
        let coords = [
            CLLocationCoordinate2D(latitude: 40.0, longitude: 2.0),
            CLLocationCoordinate2D(latitude: 41.0, longitude: 2.0),
        ]
        let result = MapSnapshotHelper.normalizeCoordinates(coords)
        #expect(result.count == 2)
        // Both x values should be 0.5 (centered) since lonRange is 0
        #expect(abs(result[0].x - 0.5) < 0.01)
        #expect(abs(result[1].x - 0.5) < 0.01)
    }

    @Test func normalize_horizontalLine_centeredVertically() {
        // Pure east-west line: latitude is constant
        let coords = [
            CLLocationCoordinate2D(latitude: 41.0, longitude: 2.0),
            CLLocationCoordinate2D(latitude: 41.0, longitude: 3.0),
        ]
        let result = MapSnapshotHelper.normalizeCoordinates(coords)
        #expect(result.count == 2)
        // Both y values should be 0.5 (centered) since latRange is 0
        #expect(abs(result[0].y - 0.5) < 0.01)
        #expect(abs(result[1].y - 0.5) < 0.01)
    }

    @Test func normalize_squareRoute_cornersAtExtremes() {
        // Square: should use full 0...1 range on both axes
        let coords = [
            CLLocationCoordinate2D(latitude: 40.0, longitude: 2.0),
            CLLocationCoordinate2D(latitude: 41.0, longitude: 2.0),
            CLLocationCoordinate2D(latitude: 41.0, longitude: 3.0),
            CLLocationCoordinate2D(latitude: 40.0, longitude: 3.0),
        ]
        let result = MapSnapshotHelper.normalizeCoordinates(coords)
        let xs = result.map(\.x)
        let ys = result.map(\.y)
        // Should span from 0 to 1 on both axes
        #expect(xs.min()! < 0.01)
        #expect(xs.max()! > 0.99)
        #expect(ys.min()! < 0.01)
        #expect(ys.max()! > 0.99)
    }
}
