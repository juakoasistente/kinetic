import Foundation

struct Session: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    var name: String
    var category: String
    var vehicle: String
    var date: Date
    var distance: Double
    var duration: TimeInterval
    var hasVideo: Bool
    var thumbnailUrl: String?
    var videoUrl: String?
    var locationName: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        name: String,
        category: String = "",
        vehicle: String = "",
        date: Date = Date(),
        distance: Double = 0,
        duration: TimeInterval = 0,
        hasVideo: Bool = false,
        thumbnailUrl: String? = nil,
        videoUrl: String? = nil,
        locationName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.category = category
        self.vehicle = vehicle
        self.date = date
        self.distance = distance
        self.duration = duration
        self.hasVideo = hasVideo
        self.thumbnailUrl = thumbnailUrl
        self.videoUrl = videoUrl
        self.locationName = locationName
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case category
        case vehicle
        case date
        case distance
        case duration
        case hasVideo = "has_video"
        case thumbnailUrl = "thumbnail_url"
        case videoUrl = "video_url"
        case locationName = "location_name"
        case createdAt = "created_at"
    }

    static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date).uppercased()
    }

    var formattedDistance: String {
        String(format: "%.1f km", distance)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var videoType: String? {
        hasVideo ? "4K Video" : nil
    }

    var videoLength: String? {
        guard hasVideo else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Mock Data

    static let mockData: [Session] = {
        let calendar = Calendar.current
        let now = Date()
        let mockUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        return [
            Session(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
                userId: mockUserId,
                name: "Sierra Route",
                category: "Performance Run",
                vehicle: "Porsche 911",
                date: calendar.date(byAdding: .day, value: -5, to: now)!,
                distance: 42.8,
                duration: 1452,
                hasVideo: false
            ),
            Session(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
                userId: mockUserId,
                name: "Coastal Loop",
                category: "Cruising",
                vehicle: "BMW M3",
                date: calendar.date(byAdding: .day, value: -9, to: now)!,
                distance: 128.5,
                duration: 6300,
                hasVideo: false
            ),
            Session(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!,
                userId: mockUserId,
                name: "Tunnel Sound Run",
                category: "Exhaust Note",
                vehicle: "Audi R8",
                date: calendar.date(byAdding: .day, value: -17, to: now)!,
                distance: 18.0,
                duration: 165,
                hasVideo: true
            ),
            Session(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000104")!,
                userId: mockUserId,
                name: "Midnight City",
                category: "Precision",
                vehicle: "Nissan GT-R",
                date: calendar.date(byAdding: .day, value: -24, to: now)!,
                distance: 18.2,
                duration: 770,
                hasVideo: false
            ),
        ]
    }()
}
