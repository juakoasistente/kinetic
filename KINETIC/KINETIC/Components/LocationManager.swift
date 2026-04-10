import Foundation
import CoreLocation
import Observation

// MARK: - TrackingSummary

struct TrackingSummary {
    let maxSpeed: Double        // km/h
    let avgSpeed: Double        // km/h
    let totalDistance: Double    // km
    let maxElevation: Double    // meters
    let elapsedTime: TimeInterval
    let routeCoordinates: [CLLocationCoordinate2D]
    let snapshots: [TelemetrySnapshot]
}

// MARK: - Constants

private enum TrackingConfig {
    static let msToKmh: Double = 3.6
    static let maxAccuracy: Double = 65          // meters — reject readings worse than this
    static let minDistanceDelta: Double = 3      // meters — ignore smaller movements (GPS jitter)
    static let maxAcceleration: Double = 40      // km/h per second — reject bigger speed jumps
    static let speedSmoothingFactor: Double = 0.3 // 0 = no smoothing, 1 = ignore new readings
    static let maxReasonableSpeed: Double = 350  // km/h — hard cap for cars
}

// MARK: - LocationManager

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {

    // Tracking state
    private(set) var currentSpeed: Double = 0       // km/h (smoothed)
    private(set) var maxSpeed: Double = 0            // km/h
    private(set) var avgSpeed: Double = 0            // km/h
    private(set) var totalDistance: Double = 0        // km
    private(set) var currentElevation: Double = 0    // meters
    private(set) var maxElevation: Double = 0        // meters
    private(set) var isTracking: Bool = false
    private(set) var routeCoordinates: [CLLocationCoordinate2D] = []
    private(set) var telemetrySnapshots: [TelemetrySnapshot] = []
    private var lastSnapshotTime: TimeInterval = -1

    // Waypoint monitoring
    private(set) var currentLocation: CLLocation?
    var startWaypoint: CLLocationCoordinate2D?
    var endWaypoint: CLLocationCoordinate2D?
    private(set) var distanceToStart: Double?
    private(set) var distanceToEnd: Double?
    var onReachedStart: (() -> Void)?
    var onReachedEnd: (() -> Void)?
    private var startTriggered = false
    private var endTriggered = false
    static let proximityThreshold: Double = 50.0

    private let manager = CLLocationManager()
    private var previousLocation: CLLocation?
    private var previousSpeed: Double = 0
    private var previousLocationTime: Date?
    private var startDate: Date?
    private var totalPausedTime: TimeInterval = 0
    private var pauseStartDate: Date?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .automotiveNavigation
    }

    // MARK: - Tracking API

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        currentSpeed = 0
        maxSpeed = 0
        avgSpeed = 0
        totalDistance = 0
        currentElevation = 0
        maxElevation = 0
        routeCoordinates = []
        telemetrySnapshots = []
        lastSnapshotTime = -1
        previousLocation = nil
        previousSpeed = 0
        previousLocationTime = nil
        totalPausedTime = 0
        pauseStartDate = nil
        startDate = Date()
        isTracking = true
        enableBackgroundUpdatesIfAvailable()
        manager.startUpdatingLocation()
    }

    /// Resume tracking after pause — keeps accumulated data
    func resumeTracking() {
        if let pauseStart = pauseStartDate {
            totalPausedTime += Date().timeIntervalSince(pauseStart)
            pauseStartDate = nil
        }
        previousLocation = nil // Don't count distance during pause
        isTracking = true
        enableBackgroundUpdatesIfAvailable()
        manager.startUpdatingLocation()
    }

    /// Pause tracking — stops GPS but keeps data
    func pauseTracking() {
        manager.stopUpdatingLocation()
        isTracking = false
        pauseStartDate = Date()
        currentSpeed = 0
    }

    private func enableBackgroundUpdatesIfAvailable() {
        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            manager.allowsBackgroundLocationUpdates = true
            manager.pausesLocationUpdatesAutomatically = false
            manager.showsBackgroundLocationIndicator = true
        }
    }

    @discardableResult
    func stopTracking() -> TrackingSummary {
        manager.stopUpdatingLocation()
        isTracking = false

        // Validate: avg speed should never exceed max speed
        let validatedAvg = min(avgSpeed, maxSpeed)

        return TrackingSummary(
            maxSpeed: maxSpeed,
            avgSpeed: validatedAvg,
            totalDistance: totalDistance,
            maxElevation: maxElevation,
            elapsedTime: elapsedTime,
            routeCoordinates: routeCoordinates,
            snapshots: telemetrySnapshots
        )
    }

    // MARK: - Waypoint Monitoring API

    func startMonitoring() {
        startTriggered = false
        endTriggered = false
        manager.startUpdatingLocation()
    }

    func stopMonitoring() {
        startWaypoint = nil
        endWaypoint = nil
        onReachedStart = nil
        onReachedEnd = nil
        distanceToStart = nil
        distanceToEnd = nil
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Fix 1: Stricter GPS accuracy filter
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= TrackingConfig.maxAccuracy else { return }

        currentLocation = location

        // Waypoint proximity checks
        if let start = startWaypoint, !startTriggered {
            let dist = location.distance(from: CLLocation(latitude: start.latitude, longitude: start.longitude))
            distanceToStart = dist
            if dist <= Self.proximityThreshold {
                startTriggered = true
                onReachedStart?()
            }
        }

        if let end = endWaypoint, !endTriggered, isTracking {
            let dist = location.distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
            distanceToEnd = dist
            if dist <= Self.proximityThreshold {
                endTriggered = true
                onReachedEnd?()
            }
        }

        // Tracking logic
        guard isTracking else { return }

        // Fix 2: Speed calculation with spike detection
        let rawSpeedKmh = max(location.speed, 0) * TrackingConfig.msToKmh

        // Check for unrealistic speed spike
        let timeDelta: TimeInterval
        if let prevTime = previousLocationTime {
            timeDelta = location.timestamp.timeIntervalSince(prevTime)
        } else {
            timeDelta = 1.0
        }

        let speedDelta = abs(rawSpeedKmh - previousSpeed)
        let maxAllowedDelta = TrackingConfig.maxAcceleration * max(timeDelta, 0.1)

        let filteredSpeed: Double
        if rawSpeedKmh > TrackingConfig.maxReasonableSpeed {
            // Hard cap: no car goes 350+ km/h
            filteredSpeed = previousSpeed
        } else if speedDelta > maxAllowedDelta && previousSpeed > 0 {
            // Spike detected: smooth towards new reading instead of jumping
            filteredSpeed = previousSpeed + (rawSpeedKmh > previousSpeed ? maxAllowedDelta : -maxAllowedDelta)
        } else {
            filteredSpeed = rawSpeedKmh
        }

        // Fix 3: Speed smoothing (rolling average)
        let smoothed = previousSpeed * TrackingConfig.speedSmoothingFactor
            + filteredSpeed * (1 - TrackingConfig.speedSmoothingFactor)
        currentSpeed = max(smoothed, 0)
        previousSpeed = currentSpeed
        previousLocationTime = location.timestamp

        // Max speed (only from validated readings)
        if currentSpeed > maxSpeed {
            maxSpeed = currentSpeed
        }

        currentElevation = location.altitude
        if currentElevation > maxElevation {
            maxElevation = currentElevation
        }

        // Fix 4: Distance with minimum delta threshold
        if let previous = previousLocation {
            let delta = location.distance(from: previous)
            if delta >= TrackingConfig.minDistanceDelta {
                totalDistance += delta / 1000.0
                routeCoordinates.append(location.coordinate)
            }
        } else {
            // First point always added
            routeCoordinates.append(location.coordinate)
        }
        previousLocation = location

        // Fix 5: Average speed uses elapsed time minus paused time
        let elapsed = elapsedTime
        if elapsed > 0 {
            avgSpeed = totalDistance / (elapsed / 3600.0)
        }

        // Capture snapshot every second
        let currentSecond = floor(elapsed)
        if currentSecond > lastSnapshotTime {
            lastSnapshotTime = currentSecond
            telemetrySnapshots.append(TelemetrySnapshot(
                timestamp: currentSecond,
                speed: currentSpeed,
                maxSpeed: maxSpeed,
                avgSpeed: min(avgSpeed, maxSpeed), // Validated
                distance: totalDistance,
                elevation: currentElevation,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("[LocationManager] Location error: \(error.localizedDescription)")
    }

    // MARK: - Helpers

    /// Elapsed tracking time, excluding paused periods
    private var elapsedTime: TimeInterval {
        guard let start = startDate else { return 0 }
        let total = Date().timeIntervalSince(start)
        return total - totalPausedTime
    }
}
