import Foundation
import CoreLocation

/// A single telemetry reading at a point in time during a session
struct TelemetrySnapshot: Codable, Sendable {
    let timestamp: TimeInterval   // seconds from session start
    let speed: Double             // km/h
    let maxSpeed: Double          // km/h cumulative
    let avgSpeed: Double          // km/h cumulative
    let distance: Double          // km cumulative
    let elevation: Double         // meters
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case timestamp
        case speed
        case maxSpeed = "max_speed"
        case avgSpeed = "avg_speed"
        case distance
        case elevation
        case latitude
        case longitude
    }
}
