import Foundation
import CoreLocation

/// Records telemetry data points over time for session playback and export.
@Observable
final class TelemetryRecorder {
    
    // MARK: - State
    
    var isRecording: Bool = false
    var dataPoints: [TelemetryDataPoint] = []
    var recordingDuration: TimeInterval = 0
    
    // MARK: - Private
    
    private var timer: Timer?
    private var startTime: Date?
    private let sampleInterval: TimeInterval = 1.0 // Record every 1 second
    
    // MARK: - Data Point
    
    struct TelemetryDataPoint: Codable, Identifiable {
        let id: UUID
        let timestamp: TimeInterval  // Seconds from start
        let speed: Double            // km/h
        let maxSpeed: Double         // km/h
        let avgSpeed: Double         // km/h
        let distance: Double         // km
        let altitude: Double         // meters
        let elevationGain: Double    // meters
        let heading: Double          // degrees
        let latitude: Double
        let longitude: Double
        let accuracy: Double         // meters
        
        init(timestamp: TimeInterval, snapshot: TelemetrySnapshot) {
            self.id = UUID()
            self.timestamp = timestamp
            self.speed = snapshot.speed
            self.maxSpeed = snapshot.maxSpeed
            self.avgSpeed = snapshot.avgSpeed
            self.distance = snapshot.distance
            self.altitude = snapshot.altitude
            self.elevationGain = snapshot.elevationGain
            self.heading = snapshot.heading
            self.latitude = snapshot.coordinate?.latitude ?? 0
            self.longitude = snapshot.coordinate?.longitude ?? 0
            self.accuracy = snapshot.accuracy
        }
    }
    
    // MARK: - Session Summary
    
    struct SessionSummary: Codable {
        let startDate: Date
        let duration: TimeInterval
        let totalDistance: Double      // km
        let maxSpeed: Double           // km/h
        let avgSpeed: Double           // km/h
        let maxAltitude: Double        // meters
        let elevationGain: Double      // meters
        let dataPointCount: Int
        let routeCoordinates: [[Double]] // [[lat, lon], ...]
    }
    
    // MARK: - Public API
    
    /// Start recording telemetry from a LocationManager
    func startRecording(locationManager: LocationManager) {
        guard !isRecording else { return }
        
        dataPoints = []
        isRecording = true
        startTime = Date()
        recordingDuration = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            guard let self, self.isRecording else { return }
            
            let snapshot = locationManager.currentTelemetry()
            let elapsed = locationManager.elapsedTime
            
            let point = TelemetryDataPoint(timestamp: elapsed, snapshot: snapshot)
            self.dataPoints.append(point)
            self.recordingDuration = elapsed
        }
    }
    
    /// Stop recording and return session summary
    func stopRecording(locationManager: LocationManager) -> SessionSummary {
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        let snapshot = locationManager.currentTelemetry()
        let route = locationManager.routeCoordinates.map { [$0.latitude, $0.longitude] }
        
        return SessionSummary(
            startDate: startTime ?? Date(),
            duration: recordingDuration,
            totalDistance: snapshot.distance,
            maxSpeed: snapshot.maxSpeed,
            avgSpeed: snapshot.avgSpeed,
            maxAltitude: snapshot.maxAltitude,
            elevationGain: snapshot.elevationGain,
            dataPointCount: dataPoints.count,
            routeCoordinates: route
        )
    }
    
    /// Pause recording
    func pauseRecording() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Resume recording
    func resumeRecording(locationManager: LocationManager) {
        guard isRecording else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            guard let self, self.isRecording else { return }
            
            let snapshot = locationManager.currentTelemetry()
            let elapsed = locationManager.elapsedTime
            
            let point = TelemetryDataPoint(timestamp: elapsed, snapshot: snapshot)
            self.dataPoints.append(point)
            self.recordingDuration = elapsed
        }
    }
    
    // MARK: - Export
    
    /// Export telemetry data as JSON
    func exportJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(dataPoints)
    }
    
    /// Export route as GPX format
    func exportGPX(sessionName: String = "Kinetic Session") -> String {
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Kinetic"
             xmlns="http://www.topografix.com/GPX/1/1">
          <trk>
            <name>\(sessionName)</name>
            <trkseg>
        
        """
        
        for point in dataPoints {
            gpx += """
                  <trkpt lat="\(point.latitude)" lon="\(point.longitude)">
                    <ele>\(point.altitude)</ele>
                    <speed>\(point.speed / 3.6)</speed>
                  </trkpt>
            
            """
        }
        
        gpx += """
            </trkseg>
          </trk>
        </gpx>
        """
        
        return gpx
    }
}
