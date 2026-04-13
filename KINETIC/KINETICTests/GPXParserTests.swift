import Testing
import Foundation
import CoreLocation
@testable import KINETIC

struct GPXParserTests {

    @Test func parse_validGPX_returnsRoute() {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Test">
            <trk>
                <name>Test Route</name>
                <trkseg>
                    <trkpt lat="41.385" lon="2.173">
                        <ele>100</ele>
                    </trkpt>
                    <trkpt lat="41.390" lon="2.180">
                        <ele>150</ele>
                    </trkpt>
                    <trkpt lat="41.395" lon="2.175">
                        <ele>120</ele>
                    </trkpt>
                </trkseg>
            </trk>
        </gpx>
        """
        let data = gpx.data(using: .utf8)!
        let route = GPXParser.parse(data: data)

        #expect(route != nil)
        #expect(route?.name == "Test Route")
        #expect(route?.coordinates.count == 3)
        #expect(route?.elevations.count == 3)

        let first = route!.coordinates[0]
        #expect(abs(first.latitude - 41.385) < 0.001)
        #expect(abs(first.longitude - 2.173) < 0.001)
    }

    @Test func parse_routePoints_works() {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
            <rte>
                <name>Route Test</name>
                <rtept lat="40.0" lon="3.0"></rtept>
                <rtept lat="41.0" lon="4.0"></rtept>
            </rte>
        </gpx>
        """
        let data = gpx.data(using: .utf8)!
        let route = GPXParser.parse(data: data)

        #expect(route != nil)
        #expect(route?.coordinates.count == 2)
        #expect(route?.name == "Route Test")
    }

    @Test func parse_emptyGPX_returnsNil() {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1"></gpx>
        """
        let data = gpx.data(using: .utf8)!
        let route = GPXParser.parse(data: data)

        #expect(route == nil)
    }

    @Test func parse_noName_defaultsToImportedRoute() {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
            <trk>
                <trkseg>
                    <trkpt lat="41.0" lon="2.0"></trkpt>
                    <trkpt lat="42.0" lon="3.0"></trkpt>
                </trkseg>
            </trk>
        </gpx>
        """
        let data = gpx.data(using: .utf8)!
        let route = GPXParser.parse(data: data)

        #expect(route?.name == "Imported Route")
    }
}
