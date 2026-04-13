import Foundation
import CoreLocation

struct GPXRoute {
    let name: String
    let coordinates: [CLLocationCoordinate2D]
    let elevations: [Double]
}

/// Parses GPX XML files into route coordinates
final class GPXParser: NSObject, XMLParserDelegate {

    static func parse(url: URL) -> GPXRoute? {
        guard let data = try? Data(contentsOf: url) else {
            print("[GPXParser] Failed to read file: \(url.lastPathComponent)")
            return nil
        }
        return parse(data: data)
    }

    static func parse(data: Data) -> GPXRoute? {
        let parser = GPXParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()

        guard !parser.coordinates.isEmpty else {
            print("[GPXParser] No coordinates found in GPX file")
            return nil
        }

        let name = parser.routeName.isEmpty ? "Imported Route" : parser.routeName

        print("[GPXParser] Parsed \(parser.coordinates.count) points, name: \(name)")
        return GPXRoute(
            name: name,
            coordinates: parser.coordinates,
            elevations: parser.elevations
        )
    }

    // MARK: - Internal State

    private var coordinates: [CLLocationCoordinate2D] = []
    private var elevations: [Double] = []
    private var routeName = ""
    private var currentElement = ""
    private var currentText = ""
    private var currentLat: Double?
    private var currentLon: Double?
    private var isInTrack = false
    private var isInRoute = false
    private var isInName = false

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "trk", "rte":
            isInTrack = true
        case "trkpt", "rtept", "wpt":
            // Track point, route point, or waypoint
            if let latStr = attributeDict["lat"], let lonStr = attributeDict["lon"],
               let lat = Double(latStr), let lon = Double(lonStr) {
                currentLat = lat
                currentLon = lon
            }
        case "name":
            isInName = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        switch elementName {
        case "trkpt", "rtept", "wpt":
            if let lat = currentLat, let lon = currentLon {
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
            currentLat = nil
            currentLon = nil
        case "ele":
            if let elevation = Double(currentText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                elevations.append(elevation)
            }
        case "name":
            if isInName && routeName.isEmpty {
                routeName = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            isInName = false
        case "trk", "rte":
            isInTrack = false
        default:
            break
        }
        currentElement = ""
    }
}
