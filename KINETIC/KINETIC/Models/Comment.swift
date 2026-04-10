import Foundation

struct Comment: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let postId: UUID
    var content: String
    let createdAt: Date

    // Joined data
    var author: Profile?

    init(
        id: UUID = UUID(),
        userId: UUID,
        postId: UUID,
        content: String,
        createdAt: Date = Date(),
        author: Profile? = nil
    ) {
        self.id = id
        self.userId = userId
        self.postId = postId
        self.content = content
        self.createdAt = createdAt
        self.author = author
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case content
        case createdAt = "created_at"
        case author = "profiles"
    }

    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var authorName: String {
        author?.nickname ?? "Unknown"
    }

    // MARK: - Mock Data

    static let mockData: [Comment] = {
        let mockPostId = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let user1 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let user2 = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        return [
            Comment(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000401")!,
                userId: user1,
                postId: mockPostId,
                content: "Incredible session! What tires were you running?",
                createdAt: Date().addingTimeInterval(-3600),
                author: Profile(id: user1, nickname: "Marco Rivera")
            ),
            Comment(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000402")!,
                userId: user2,
                postId: mockPostId,
                content: "The grip on those corners is insane. Great route choice!",
                createdAt: Date().addingTimeInterval(-7200),
                author: Profile(id: user2, nickname: "Sara Chen")
            ),
        ]
    }()
}
