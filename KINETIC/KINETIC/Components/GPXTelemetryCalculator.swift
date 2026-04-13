import Foundation
import CoreLocation

struct GPXTelemetryCalculator {

    /// Calculate telemetry snapshots from GPX coordinates
    /// Distributes points evenly across the video duration
    static func calculate(route: GPXRoute, videoDuration: TimeInterval) -> GPXTelemetryResult {
        guard route.coordinates.count >= 2, videoDuration > 0 else {
            return GPXTelemetryResult(snapshots: [], totalDistance: 0, maxSpeed: 0, avgSpeed: 0)
        }

        // Calculate distances between consecutive points
        var distances: [Double] = [0] // first point = 0
        var totalDistance: Double = 0

        for i in 1..<route.coordinates.count {
            let from = CLLocation(latitude: route.coordinates[i - 1].latitude, longitude: route.coordinates[i - 1].longitude)
            let to = CLLocation(latitude: route.coordinates[i].latitude, longitude: route.coordinates[i].longitude)
            let delta = to.distance(from: from) / 1000.0 // km
            totalDistance += delta
            distances.append(totalDistance)
        }

        // Generate one snapshot per second, interpolating along the route
        let totalSeconds = Int(videoDuration)
        guard totalSeconds > 0 else {
            return GPXTelemetryResult(snapshots: [], totalDistance: totalDistance, maxSpeed: 0, avgSpeed: 0)
        }

        var snapshots: [TelemetrySnapshot] = []
        var maxSpeed: Double = 0
        let avgSpeed = totalDistance / (videoDuration / 3600.0)

        for second in 0...totalSeconds {
            let progress = Double(second) / Double(totalSeconds)
            let targetDist = progress * totalDistance

            // Find the two GPX points we're between
            var segmentIndex = 0
            for i in 1..<distances.count {
                if distances[i] >= targetDist {
                    segmentIndex = i - 1
                    break
                }
                segmentIndex = i - 1
            }

            let nextIndex = min(segmentIndex + 1, route.coordinates.count - 1)
            let segmentStart = distances[segmentIndex]
            let segmentEnd = distances[nextIndex]
            let segmentLength = segmentEnd - segmentStart

            // Interpolate position within segment
            let segmentProgress = segmentLength > 0 ? (targetDist - segmentStart) / segmentLength : 0
            let lat = route.coordinates[segmentIndex].latitude +
                (route.coordinates[nextIndex].latitude - route.coordinates[segmentIndex].latitude) * segmentProgress
            let lon = route.coordinates[segmentIndex].longitude +
                (route.coordinates[nextIndex].longitude - route.coordinates[segmentIndex].longitude) * segmentProgress

            // Calculate speed from distance delta
            let speed: Double
            if second > 0, let prev = snapshots.last {
                let distDelta = targetDist - prev.distance
                speed = distDelta * 3600 // km/s to km/h
            } else {
                speed = avgSpeed
            }

            let clampedSpeed = min(max(speed, 0), 350)
            if clampedSpeed > maxSpeed { maxSpeed = clampedSpeed }

            let elevation: Double
            if !route.elevations.isEmpty {
                let eleIndex = min(segmentIndex, route.elevations.count - 1)
                let nextEleIndex = min(nextIndex, route.elevations.count - 1)
                elevation = route.elevations[eleIndex] +
                    (route.elevations[nextEleIndex] - route.elevations[eleIndex]) * segmentProgress
            } else {
                elevation = 0
            }

            snapshots.append(TelemetrySnapshot(
                timestamp: TimeInterval(second),
                speed: clampedSpeed,
                maxSpeed: maxSpeed,
                avgSpeed: avgSpeed,
                distance: targetDist,
                elevation: elevation,
                latitude: lat,
                longitude: lon
            ))
        }

        return GPXTelemetryResult(
            snapshots: snapshots,
            totalDistance: totalDistance,
            maxSpeed: maxSpeed,
            avgSpeed: avgSpeed
        )
    }
}

struct GPXTelemetryResult {
    let snapshots: [TelemetrySnapshot]
    let totalDistance: Double  // km
    let maxSpeed: Double      // km/h
    let avgSpeed: Double      // km/h
}
