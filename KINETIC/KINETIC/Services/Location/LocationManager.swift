import Foundation
import CoreLocation
import Combine

/// Manages GPS location updates for real-time speed, distance, altitude, and route tracking.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Published State
    
    /// Current speed in m/s (-1 if unavailable)
    var currentSpeed: Double = 0
    
    /// Current speed in km/h
    var currentSpeedKmh: Double { max(0, currentSpeed * 3.6) }
    
    /// Current speed in mph
    var currentSpeedMph: Double { max(0, currentSpeed * 2.237) }
    
    /// Maximum speed recorded in m/s
    var maxSpeed: Double = 0
    
    /// Maximum speed in km/h
    var maxSpeedKmh: Double { maxSpeed * 3.6 }
    
    /// Average speed in km/h (calculated from distance/time)
    var averageSpeedKmh: Double {
        guard elapsedTime > 0 else { return 0 }
        return (totalDistance / 1000) / (elapsedTime / 3600) 
    }
    
    /// Total distance in meters
    var totalDistance: Double = 0
    
    /// Total distance in kilometers
    var totalDistanceKm: Double { totalDistance / 1000 }
    
    /// Current altitude in meters
    var currentAltitude: Double = 0
    
    /// Maximum altitude recorded
    var maxAltitude: Double = 0
    
    /// Minimum altitude recorded
    var minAltitude: Double = 0
    
    /// Total elevation gain in meters
    var elevationGain: Double = 0
    
    /// Current heading/bearing in degrees (0-360)
    var currentHeading: Double = 0
    
    /// Current GPS accuracy in meters
    var horizontalAccuracy: Double = 0
    
    /// Whether GPS has a valid fix
    var hasValidFix: Bool = false
    
    /// Current coordinate
    var currentCoordinate: CLLocationCoordinate2D?
    
    /// Route as array of coordinates
    var routeCoordinates: [CLLocationCoordinate2D] = []
    
    /// Whether tracking is active
    var isTracking: Bool = false
    
    /// Elapsed time in seconds
    var elapsedTime: TimeInterval = 0
    
    /// GPS signal strength (0-3: none, weak, moderate, strong)
    var signalStrength: Int {
        if !hasValidFix { return 0 }
        if horizontalAccuracy > 30 { return 1 }
        if horizontalAccuracy > 10 { return 2 }
        return 3
    }
    
    /// Authorization status
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Private
    
    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation?
    private var previousAltitude: Double?
    private var startTime: Date?
    private var timer: Timer?
    
    // Kalman filter state for speed smoothing
    private var kalmanSpeed: Double = 0
    private var kalmanUncertainty: Double = 1
    private let processNoise: Double = 0.5
    private let measurementNoise: Double = 2.0
    
    // MARK: - Init
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 2 // Update every 2 meters
        locationManager.activityType = .automotiveNavigation
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Public API
    
    /// Request location permissions
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Start tracking location, speed, and route
    func startTracking() {
        guard !isTracking else { return }
        
        reset()
        isTracking = true
        startTime = Date()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        // Timer for elapsed time
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }
    
    /// Stop tracking
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        timer?.invalidate()
        timer = nil
    }
    
    /// Pause tracking (keeps data, stops GPS)
    func pauseTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
    }
    
    /// Resume tracking after pause
    func resumeTracking() {
        guard !isTracking else { return }
        isTracking = true
        let pausedElapsed = elapsedTime
        startTime = Date().addingTimeInterval(-pausedElapsed)
        locationManager.startUpdatingLocation()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }
    
    /// Reset all data
    func reset() {
        currentSpeed = 0
        maxSpeed = 0
        totalDistance = 0
        currentAltitude = 0
        maxAltitude = 0
        minAltitude = 0
        elevationGain = 0
        currentHeading = 0
        elapsedTime = 0
        routeCoordinates = []
        previousLocation = nil
        previousAltitude = nil
        startTime = nil
        kalmanSpeed = 0
        kalmanUncertainty = 1
        hasValidFix = false
    }
    
    /// Get a snapshot of current telemetry
    func currentTelemetry() -> TelemetrySnapshot {
        TelemetrySnapshot(
            speed: currentSpeedKmh,
            maxSpeed: maxSpeedKmh,
            avgSpeed: averageSpeedKmh,
            distance: totalDistanceKm,
            altitude: currentAltitude,
            maxAltitude: maxAltitude,
            elevationGain: elevationGain,
            heading: currentHeading,
            elapsedTime: elapsedTime,
            coordinate: currentCoordinate,
            accuracy: horizontalAccuracy,
            signalStrength: signalStrength
        )
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out inaccurate readings
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 else { return }
        
        horizontalAccuracy = location.horizontalAccuracy
        hasValidFix = true
        currentCoordinate = location.coordinate
        
        // Speed (with Kalman filtering for smoothing)
        if location.speed >= 0 {
            let rawSpeed = location.speed
            
            // Kalman filter update
            let predictedSpeed = kalmanSpeed
            let predictedUncertainty = kalmanUncertainty + processNoise
            let kalmanGain = predictedUncertainty / (predictedUncertainty + measurementNoise)
            kalmanSpeed = predictedSpeed + kalmanGain * (rawSpeed - predictedSpeed)
            kalmanUncertainty = (1 - kalmanGain) * predictedUncertainty
            
            currentSpeed = max(0, kalmanSpeed)
            
            // Filter out walking-speed noise when stationary
            if currentSpeed * 3.6 < 2 { currentSpeed = 0 }
            
            if currentSpeed > maxSpeed {
                maxSpeed = currentSpeed
            }
        }
        
        // Distance
        if let prev = previousLocation {
            let delta = location.distance(from: prev)
            // Only add distance if moving (speed > 2 km/h) and delta is reasonable
            if delta < 100 && currentSpeed * 3.6 > 2 {
                totalDistance += delta
            }
        }
        
        // Altitude
        if location.verticalAccuracy >= 0 && location.verticalAccuracy < 20 {
            currentAltitude = location.altitude
            
            if previousAltitude == nil {
                minAltitude = location.altitude
                maxAltitude = location.altitude
            }
            
            if location.altitude > maxAltitude { maxAltitude = location.altitude }
            if location.altitude < minAltitude { minAltitude = location.altitude }
            
            // Elevation gain (only count uphill)
            if let prev = previousAltitude {
                let altDelta = location.altitude - prev
                if altDelta > 1 { // Threshold to avoid GPS noise
                    elevationGain += altDelta
                }
            }
            previousAltitude = location.altitude
        }
        
        // Route
        routeCoordinates.append(location.coordinate)
        
        previousLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            currentHeading = newHeading.trueHeading
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Error: \(error.localizedDescription)")
        hasValidFix = false
    }
}

// MARK: - Telemetry Snapshot

struct TelemetrySnapshot {
    let speed: Double           // km/h
    let maxSpeed: Double        // km/h
    let avgSpeed: Double        // km/h
    let distance: Double        // km
    let altitude: Double        // meters
    let maxAltitude: Double     // meters
    let elevationGain: Double   // meters
    let heading: Double         // degrees
    let elapsedTime: TimeInterval // seconds
    let coordinate: CLLocationCoordinate2D?
    let accuracy: Double        // meters
    let signalStrength: Int     // 0-3
}
