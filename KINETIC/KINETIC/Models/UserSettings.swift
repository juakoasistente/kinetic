import Foundation

struct UserSettings: Codable, Identifiable, Sendable {
    let userId: UUID
    var showSpeed: Bool
    var showDistance: Bool
    var showTime: Bool
    var showGps: Bool
    var useMetric: Bool
    var language: String
    var updatedAt: Date

    var id: UUID { userId }

    init(
        userId: UUID,
        showSpeed: Bool = true,
        showDistance: Bool = true,
        showTime: Bool = false,
        showGps: Bool = true,
        useMetric: Bool = true,
        language: String = "en",
        updatedAt: Date = Date()
    ) {
        self.userId = userId
        self.showSpeed = showSpeed
        self.showDistance = showDistance
        self.showTime = showTime
        self.showGps = showGps
        self.useMetric = useMetric
        self.language = language
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case showSpeed = "show_speed"
        case showDistance = "show_distance"
        case showTime = "show_time"
        case showGps = "show_gps"
        case useMetric = "use_metric"
        case language
        case updatedAt = "updated_at"
    }
}
