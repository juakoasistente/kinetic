import Testing
import Foundation
@testable import KINETIC

struct TelemetrySnapshotTests {

    @Test func codable_roundtrip() throws {
        let snapshot = TelemetrySnapshot(
            timestamp: 42.0,
            speed: 87.5,
            maxSpeed: 142.0,
            avgSpeed: 76.3,
            distance: 12.4,
            elevation: 350.0,
            latitude: 41.389,
            longitude: 2.174
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TelemetrySnapshot.self, from: data)

        #expect(decoded.timestamp == 42.0)
        #expect(decoded.speed == 87.5)
        #expect(decoded.maxSpeed == 142.0)
        #expect(decoded.avgSpeed == 76.3)
        #expect(decoded.distance == 12.4)
        #expect(decoded.elevation == 350.0)
        #expect(decoded.latitude == 41.389)
        #expect(decoded.longitude == 2.174)
    }

    @Test func codable_snakeCaseKeys() throws {
        let json = """
        {
            "timestamp": 10.0,
            "speed": 50.0,
            "max_speed": 100.0,
            "avg_speed": 60.0,
            "distance": 5.5,
            "elevation": 200.0,
            "latitude": 40.0,
            "longitude": 3.0
        }
        """
        let data = json.data(using: .utf8)!
        let snapshot = try JSONDecoder().decode(TelemetrySnapshot.self, from: data)

        #expect(snapshot.maxSpeed == 100.0)
        #expect(snapshot.avgSpeed == 60.0)
    }

    @Test func dbTelemetryData_withSnapshots() throws {
        let snapshots = [
            TelemetrySnapshot(timestamp: 0, speed: 0, maxSpeed: 0, avgSpeed: 0, distance: 0, elevation: 0, latitude: 41.0, longitude: 2.0),
            TelemetrySnapshot(timestamp: 1, speed: 50, maxSpeed: 50, avgSpeed: 50, distance: 0.01, elevation: 100, latitude: 41.001, longitude: 2.001),
        ]

        let telemetry = DBTelemetryData(
            sessionId: UUID(),
            maxSpeed: 50,
            avgSpeed: 50,
            distance: 0.01,
            snapshots: snapshots
        )

        #expect(telemetry.snapshots?.count == 2)
        #expect(telemetry.snapshots?[1].speed == 50)
    }

    @Test func array_encodeDecode() throws {
        var snapshots: [TelemetrySnapshot] = []
        for i in 0..<60 {
            let ts = TimeInterval(i)
            let spd = Double(i) * 2
            let dist = Double(i) * 0.01
            let lat = 41.0 + Double(i) * 0.0001
            let lon = 2.0 + Double(i) * 0.0001
            snapshots.append(TelemetrySnapshot(
                timestamp: ts, speed: spd, maxSpeed: spd,
                avgSpeed: Double(i), distance: dist,
                elevation: 100, latitude: lat, longitude: lon
            ))
        }

        let data = try JSONEncoder().encode(snapshots)
        let decoded = try JSONDecoder().decode([TelemetrySnapshot].self, from: data)

        #expect(decoded.count == 60)
        let lastTimestamp = decoded.last?.timestamp ?? 0
        #expect(lastTimestamp == 59)
        let lastSpeed = decoded.last?.speed ?? 0
        #expect(lastSpeed == 118)
    }
}
