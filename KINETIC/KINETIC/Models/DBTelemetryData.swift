import Foundation

struct DBTelemetryData: Codable, Identifiable, Sendable {
    let id: UUID
    let sessionId: UUID
    var maxSpeed: Double
    var avgSpeed: Double
    var distance: Double
    var elevation: Double
    var maxAltitude: Double
    var fuelConsumption: Double
    var peakGForce: Double
    var engineTemp: Double?
    var snapshots: [TelemetrySnapshot]?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        maxSpeed: Double = 0,
        avgSpeed: Double = 0,
        distance: Double = 0,
        elevation: Double = 0,
        maxAltitude: Double = 0,
        fuelConsumption: Double = 0,
        peakGForce: Double = 0,
        engineTemp: Double? = nil,
        snapshots: [TelemetrySnapshot]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.maxSpeed = maxSpeed
        self.avgSpeed = avgSpeed
        self.distance = distance
        self.elevation = elevation
        self.maxAltitude = maxAltitude
        self.fuelConsumption = fuelConsumption
        self.peakGForce = peakGForce
        self.engineTemp = engineTemp
        self.snapshots = snapshots
        self.createdAt = createdAt
    }

    func toTelemetryData(sessionTime: TimeInterval) -> TelemetryData {
        TelemetryData(
            speed: avgSpeed,
            gForce: peakGForce,
            sessionTime: sessionTime,
            distance: distance,
            elevation: elevation,
            maxAltitude: maxAltitude,
            fuelConsumption: fuelConsumption
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case maxSpeed = "max_speed"
        case avgSpeed = "avg_speed"
        case distance
        case elevation
        case maxAltitude = "max_altitude"
        case fuelConsumption = "fuel_consumption"
        case peakGForce = "peak_g_force"
        case engineTemp = "engine_temp"
        case snapshots
        case createdAt = "created_at"
    }
}
