import Foundation
import CoreLocation

/// ViewModel for the Record screen — manages GPS tracking, telemetry recording, and session state.
@Observable
final class RecordViewModel {
    
    // MARK: - State
    
    enum RecordingState {
        case idle        // Not recording, ready to start
        case recording   // Actively recording
        case paused      // Recording paused
    }
    
    var state: RecordingState = .idle
    var useMetric: Bool = true // true = km/h, false = mph
    var showDebugInfo: Bool = false
    
    // MARK: - Services
    
    let locationManager = LocationManager()
    let telemetryRecorder = TelemetryRecorder()
    
    // MARK: - Computed Properties
    
    var speedDisplay: String {
        let speed = useMetric ? locationManager.currentSpeedKmh : locationManager.currentSpeedMph
        return SpeedFormatter.speed(speed)
    }
    
    var speedUnit: String {
        useMetric ? "km/h" : "mph"
    }
    
    var maxSpeedDisplay: String {
        let speed = useMetric ? locationManager.maxSpeedKmh : (locationManager.maxSpeedKmh * 0.621371)
        return SpeedFormatter.speed(speed)
    }
    
    var avgSpeedDisplay: String {
        let speed = useMetric ? locationManager.averageSpeedKmh : (locationManager.averageSpeedKmh * 0.621371)
        return SpeedFormatter.speed(speed)
    }
    
    var distanceDisplay: String {
        SpeedFormatter.distanceCompact(locationManager.totalDistanceKm)
    }
    
    var distanceUnit: String {
        SpeedFormatter.distanceUnit(locationManager.totalDistanceKm)
    }
    
    var timeDisplay: String {
        SpeedFormatter.time(locationManager.elapsedTime)
    }
    
    var altitudeDisplay: String {
        SpeedFormatter.altitudeCompact(locationManager.currentAltitude)
    }
    
    var elevationGainDisplay: String {
        SpeedFormatter.altitudeCompact(locationManager.elevationGain)
    }
    
    var headingDisplay: String {
        SpeedFormatter.heading(locationManager.currentHeading)
    }
    
    var isRecording: Bool { state == .recording }
    var isPaused: Bool { state == .paused }
    var hasStarted: Bool { state != .idle }
    
    var hasLocationPermission: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
    
    // MARK: - Actions
    
    /// Request location permission
    func requestPermission() {
        locationManager.requestPermission()
    }
    
    /// Start a new recording session
    func startRecording() {
        guard hasLocationPermission else {
            requestPermission()
            return
        }
        
        state = .recording
        locationManager.startTracking()
        telemetryRecorder.startRecording(locationManager: locationManager)
    }
    
    /// Pause the current recording
    func pauseRecording() {
        state = .paused
        locationManager.pauseTracking()
        telemetryRecorder.pauseRecording()
    }
    
    /// Resume a paused recording
    func resumeRecording() {
        state = .recording
        locationManager.resumeTracking()
        telemetryRecorder.resumeRecording(locationManager: locationManager)
    }
    
    /// Stop recording and get session summary
    func stopRecording() -> TelemetryRecorder.SessionSummary {
        let summary = telemetryRecorder.stopRecording(locationManager: locationManager)
        locationManager.stopTracking()
        state = .idle
        return summary
    }
    
    /// Discard the current recording
    func discardRecording() {
        locationManager.stopTracking()
        locationManager.reset()
        telemetryRecorder.pauseRecording()
        state = .idle
    }
    
    /// Toggle between metric and imperial
    func toggleUnits() {
        useMetric.toggle()
    }
}
