import Foundation
import CoreLocation

/// Parses GPX files and extracts telemetry data (coordinates, speed, altitude, time).
final class GPXParser: NSObject, XMLParserDelegate {
    
    // MARK: - Types
    
    struct GPXTrackPoint: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let altitude: Double       // meters
        let timestamp: Date
        let speed: Double?         // m/s (from GPX extension or calculated)
        let heartRate: Int?        // bpm (from GPX extension)
        let cadence: Int?          // rpm (from GPX extension)
        let power: Int?            // watts (from GPX extension)
    }
    
    struct GPXTrack {
        let name: String?
        let points: [GPXTrackPoint]
        
        // MARK: - Computed properties
        
        var startTime: Date? { points.first?.timestamp }
        var endTime: Date? { points.last?.timestamp }
        var duration: TimeInterval {
            guard let start = startTime, let end = endTime else { return 0 }
            return end.timeIntervalSince(start)
        }
        
        var totalDistance: Double {
            var distance: Double = 0
            for i in 1..<points.count {
                let prev = CLLocation(latitude: points[i-1].coordinate.latitude, longitude: points[i-1].coordinate.longitude)
                let curr = CLLocation(latitude: points[i].coordinate.latitude, longitude: points[i].coordinate.longitude)
                distance += curr.distance(from: prev)
            }
            return distance
        }
        
        var totalDistanceKm: Double { totalDistance / 1000 }
        
        var maxSpeed: Double {
            let speeds = calculatedSpeeds()
            return (speeds.max() ?? 0) * 3.6 // km/h
        }
        
        var avgSpeed: Double {
            guard duration > 0 else { return 0 }
            return (totalDistance / 1000) / (duration / 3600) // km/h
        }
        
        var maxAltitude: Double {
            points.map(\.altitude).max() ?? 0
        }
        
        var minAltitude: Double {
            points.map(\.altitude).min() ?? 0
        }
        
        var elevationGain: Double {
            var gain: Double = 0
            for i in 1..<points.count {
                let delta = points[i].altitude - points[i-1].altitude
                if delta > 1 { gain += delta } // threshold for noise
            }
            return gain
        }
        
        /// Calculate speeds between each pair of points (m/s)
        func calculatedSpeeds() -> [Double] {
            guard points.count > 1 else { return [0] }
            
            var speeds: [Double] = [0] // First point has 0 speed
            for i in 1..<points.count {
                // Use GPX speed if available
                if let speed = points[i].speed, speed >= 0 {
                    speeds.append(speed)
                    continue
                }
                
                // Otherwise calculate from distance/time
                let prev = CLLocation(latitude: points[i-1].coordinate.latitude, longitude: points[i-1].coordinate.longitude)
                let curr = CLLocation(latitude: points[i].coordinate.latitude, longitude: points[i].coordinate.longitude)
                let dist = curr.distance(from: prev)
                let time = points[i].timestamp.timeIntervalSince(points[i-1].timestamp)
                
                if time > 0 {
                    speeds.append(dist / time)
                } else {
                    speeds.append(speeds.last ?? 0)
                }
            }
            return speeds
        }
        
        /// Get interpolated data at a specific time offset from start
        func dataAt(timeOffset: TimeInterval) -> InterpolatedData? {
            guard let start = startTime, points.count > 1 else { return nil }
            
            let targetTime = start.addingTimeInterval(timeOffset)
            
            // Find the two surrounding points
            var beforeIdx = 0
            var afterIdx = 1
            
            for i in 0..<points.count - 1 {
                if points[i].timestamp <= targetTime && points[i+1].timestamp >= targetTime {
                    beforeIdx = i
                    afterIdx = i + 1
                    break
                }
                if i == points.count - 2 {
                    beforeIdx = i
                    afterIdx = i + 1
                }
            }
            
            let before = points[beforeIdx]
            let after = points[afterIdx]
            
            let timeBetween = after.timestamp.timeIntervalSince(before.timestamp)
            let fraction = timeBetween > 0 ? (targetTime.timeIntervalSince(before.timestamp)) / timeBetween : 0
            let clampedFraction = min(max(fraction, 0), 1)
            
            // Interpolate
            let lat = before.coordinate.latitude + (after.coordinate.latitude - before.coordinate.latitude) * clampedFraction
            let lon = before.coordinate.longitude + (after.coordinate.longitude - before.coordinate.longitude) * clampedFraction
            let alt = before.altitude + (after.altitude - before.altitude) * clampedFraction
            
            // Speed from calculated speeds
            let speeds = calculatedSpeeds()
            let speedBefore = beforeIdx < speeds.count ? speeds[beforeIdx] : 0
            let speedAfter = afterIdx < speeds.count ? speeds[afterIdx] : 0
            let speed = (speedBefore + (speedAfter - speedBefore) * clampedFraction) * 3.6 // km/h
            
            // Accumulated distance up to this point
            var dist: Double = 0
            for i in 1...min(beforeIdx, points.count - 1) {
                let p = CLLocation(latitude: points[i-1].coordinate.latitude, longitude: points[i-1].coordinate.longitude)
                let c = CLLocation(latitude: points[i].coordinate.latitude, longitude: points[i].coordinate.longitude)
                dist += c.distance(from: p)
            }
            
            // Accumulated elevation gain
            var elGain: Double = 0
            for i in 1...min(beforeIdx, points.count - 1) {
                let delta = points[i].altitude - points[i-1].altitude
                if delta > 1 { elGain += delta }
            }
            
            return InterpolatedData(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                altitude: alt,
                speed: max(0, speed),
                distance: dist / 1000, // km
                elevationGain: elGain,
                elapsed: timeOffset,
                heading: calculateHeading(from: before.coordinate, to: after.coordinate)
            )
        }
        
        private func calculateHeading(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
            let dLon = (to.longitude - from.longitude) * .pi / 180
            let lat1 = from.latitude * .pi / 180
            let lat2 = to.latitude * .pi / 180
            let y = sin(dLon) * cos(lat2)
            let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
            var heading = atan2(y, x) * 180 / .pi
            if heading < 0 { heading += 360 }
            return heading
        }
    }
    
    struct InterpolatedData {
        let coordinate: CLLocationCoordinate2D
        let altitude: Double    // meters
        let speed: Double       // km/h
        let distance: Double    // km
        let elevationGain: Double // meters
        let elapsed: TimeInterval // seconds
        let heading: Double     // degrees
    }
    
    // MARK: - Parsing
    
    private var currentElement = ""
    private var currentTrackName: String?
    private var trackPoints: [GPXTrackPoint] = []
    
    // Current point being parsed
    private var currentLat: Double = 0
    private var currentLon: Double = 0
    private var currentAlt: Double?
    private var currentTime: Date?
    private var currentSpeed: Double?
    private var currentHR: Int?
    private var currentCadence: Int?
    private var currentPower: Int?
    private var characterBuffer = ""
    
    private let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    
    private let dateFormatterAlt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    
    /// Parse a GPX file from URL
    func parse(url: URL) -> GPXTrack? {
        guard let parser = XMLParser(contentsOf: url) else { return nil }
        
        trackPoints = []
        currentTrackName = nil
        parser.delegate = self
        
        guard parser.parse() else { return nil }
        
        return GPXTrack(name: currentTrackName, points: trackPoints)
    }
    
    /// Parse GPX from Data
    func parse(data: Data) -> GPXTrack? {
        let parser = XMLParser(data: data)
        
        trackPoints = []
        currentTrackName = nil
        parser.delegate = self
        
        guard parser.parse() else { return nil }
        
        return GPXTrack(name: currentTrackName, points: trackPoints)
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        characterBuffer = ""
        
        if elementName == "trkpt" || elementName == "rtept" {
            currentLat = Double(attributeDict["lat"] ?? "0") ?? 0
            currentLon = Double(attributeDict["lon"] ?? "0") ?? 0
            currentAlt = nil
            currentTime = nil
            currentSpeed = nil
            currentHR = nil
            currentCadence = nil
            currentPower = nil
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        characterBuffer += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        let value = characterBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch elementName {
        case "name":
            if currentTrackName == nil { currentTrackName = value }
            
        case "ele":
            currentAlt = Double(value)
            
        case "time":
            currentTime = dateFormatter.date(from: value) ?? dateFormatterAlt.date(from: value)
            
        case "speed":
            currentSpeed = Double(value)
            
        case "hr", "gpxtpx:hr":
            currentHR = Int(value)
            
        case "cad", "gpxtpx:cad":
            currentCadence = Int(value)
            
        case "power", "gpxtpx:power":
            currentPower = Int(value)
            
        case "trkpt", "rtept":
            if let time = currentTime {
                let point = GPXTrackPoint(
                    coordinate: CLLocationCoordinate2D(latitude: currentLat, longitude: currentLon),
                    altitude: currentAlt ?? 0,
                    timestamp: time,
                    speed: currentSpeed,
                    heartRate: currentHR,
                    cadence: currentCadence,
                    power: currentPower
                )
                trackPoints.append(point)
            }
            
        default:
            break
        }
        
        currentElement = ""
    }
}
