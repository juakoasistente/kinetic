import Foundation

/// Formats speed, distance, time, and altitude values for display in the overlay.
enum SpeedFormatter {
    
    // MARK: - Speed
    
    /// Format speed for display (e.g., "127" or "0")
    static func speed(_ kmh: Double) -> String {
        if kmh < 1 { return "0" }
        return String(Int(round(kmh)))
    }
    
    /// Format speed with one decimal (e.g., "127.5")
    static func speedDecimal(_ kmh: Double) -> String {
        if kmh < 1 { return "0.0" }
        return String(format: "%.1f", kmh)
    }
    
    /// Convert km/h to mph
    static func kmhToMph(_ kmh: Double) -> Double {
        kmh * 0.621371
    }
    
    // MARK: - Distance
    
    /// Format distance (e.g., "12.5 km" or "850 m")
    static func distance(_ km: Double) -> String {
        if km < 1 {
            return String(format: "%.0f m", km * 1000)
        } else if km < 10 {
            return String(format: "%.2f km", km)
        } else {
            return String(format: "%.1f km", km)
        }
    }
    
    /// Format distance compact (e.g., "12.5")
    static func distanceCompact(_ km: Double) -> String {
        if km < 1 {
            return String(format: "%.0f", km * 1000)
        } else if km < 10 {
            return String(format: "%.2f", km)
        } else {
            return String(format: "%.1f", km)
        }
    }
    
    /// Distance unit label
    static func distanceUnit(_ km: Double) -> String {
        km < 1 ? "m" : "km"
    }
    
    // MARK: - Time
    
    /// Format elapsed time as HH:MM:SS or MM:SS
    static func time(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
    
    /// Format time compact (e.g., "1:23:45")
    static func timeCompact(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }
    
    // MARK: - Altitude
    
    /// Format altitude (e.g., "1,250 m")
    static func altitude(_ meters: Double) -> String {
        if abs(meters) < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.0f m", meters)
        }
    }
    
    /// Format altitude compact
    static func altitudeCompact(_ meters: Double) -> String {
        String(format: "%.0f", meters)
    }
    
    // MARK: - Heading
    
    /// Format heading as cardinal direction (N, NE, E, SE, S, SW, W, NW)
    static func heading(_ degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int(round(degrees / 45)) % 8
        return directions[index]
    }
    
    // MARK: - G-Force (calculated from speed changes)
    
    /// Calculate approximate G-force from speed change over time
    static func gForce(speedDelta: Double, timeDelta: TimeInterval) -> Double {
        guard timeDelta > 0 else { return 0 }
        let acceleration = (speedDelta / 3.6) / timeDelta // m/s²
        return acceleration / 9.81
    }
}
