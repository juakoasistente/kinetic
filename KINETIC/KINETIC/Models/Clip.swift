import Foundation

struct Clip: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    var sessionId: UUID?
    var title: String
    var videoUrl: String
    var thumbnailUrl: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        sessionId: UUID? = nil,
        title: String = "",
        videoUrl: String,
        thumbnailUrl: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.sessionId = sessionId
        self.title = title
        self.videoUrl = videoUrl
        self.thumbnailUrl = thumbnailUrl
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionId = "session_id"
        case title
        case videoUrl = "video_url"
        case thumbnailUrl = "thumbnail_url"
        case createdAt = "created_at"
    }

    static func == (lhs: Clip, rhs: Clip) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Mock Data

    static let mockData: [Clip] = {
        let mockUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        return [
            Clip(id: UUID(), userId: mockUserId, title: "Sunday Night Rush", videoUrl: "https://example.com/clip1.mp4", thumbnailUrl: nil),
            Clip(id: UUID(), userId: mockUserId, title: "Driving fast at dawn", videoUrl: "https://example.com/clip2.mp4", thumbnailUrl: nil),
            Clip(id: UUID(), userId: mockUserId, title: "Weekend Getaway", videoUrl: "https://example.com/clip3.mp4", thumbnailUrl: nil),
            Clip(id: UUID(), userId: mockUserId, title: "Just a regular day", videoUrl: "https://example.com/clip4.mp4", thumbnailUrl: nil),
            Clip(id: UUID(), userId: mockUserId, title: "Sunset Run", videoUrl: "https://example.com/clip5.mp4", thumbnailUrl: nil),
        ]
    }()
}
