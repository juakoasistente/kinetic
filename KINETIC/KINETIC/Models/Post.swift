import Foundation

struct Post: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    var sessionId: UUID?
    var description: String
    var visibility: PostVisibility
    let createdAt: Date
    var updatedAt: Date

    // Joined data (not stored in posts table)
    var author: Profile?
    var session: Session?
    var media: [PostMedia]?
    var likesCount: Int?
    var commentsCount: Int?
    var isLikedByMe: Bool?
    var isBookmarkedByMe: Bool?

    init(
        id: UUID = UUID(),
        userId: UUID,
        sessionId: UUID? = nil,
        description: String = "",
        visibility: PostVisibility = .public,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        author: Profile? = nil,
        session: Session? = nil,
        media: [PostMedia]? = nil,
        likesCount: Int? = nil,
        commentsCount: Int? = nil,
        isLikedByMe: Bool? = nil,
        isBookmarkedByMe: Bool? = nil
    ) {
        self.id = id
        self.userId = userId
        self.sessionId = sessionId
        self.description = description
        self.visibility = visibility
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.author = author
        self.session = session
        self.media = media
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.isLikedByMe = isLikedByMe
        self.isBookmarkedByMe = isBookmarkedByMe
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionId = "session_id"
        case description
        case visibility
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case author = "profiles"
        case session = "sessions"
        case media = "post_media"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case isLikedByMe = "is_liked_by_me"
        case isBookmarkedByMe = "is_bookmarked_by_me"
    }

    static func == (lhs: Post, rhs: Post) -> Bool {
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

    var authorAvatarUrl: String? {
        author?.avatarUrl
    }

    // MARK: - Mock Data

    static let mockData: [Post] = {
        let mockUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let mockProfile = Profile(
            id: mockUserId,
            nickname: "Alex García",
            bio: "Car enthusiast",
            avatarUrl: nil,
            tier: "pro"
        )
        let mockSession = Session(
            userId: mockUserId,
            name: "Sierra Route",
            category: "Performance Run",
            vehicle: "Mercedes AMG",
            distance: 48.2,
            duration: 2927
        )
        return [
            Post(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
                userId: mockUserId,
                sessionId: mockSession.id,
                description: "Amazing drive through the mountains. The grip on these corners was incredible!",
                visibility: .public,
                author: mockProfile,
                session: mockSession,
                media: PostMedia.mockData,
                likesCount: 24,
                commentsCount: 8,
                isLikedByMe: false,
                isBookmarkedByMe: false
            ),
            Post(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
                userId: mockUserId,
                description: "Just a quick sunset run. Nothing beats golden hour driving.",
                visibility: .public,
                author: mockProfile,
                likesCount: 12,
                commentsCount: 3,
                isLikedByMe: true,
                isBookmarkedByMe: false
            ),
        ]
    }()
}

// MARK: - Post Visibility

enum PostVisibility: String, Codable, CaseIterable, Sendable {
    case `public` = "public"
    case unlisted = "unlisted"
    case `private` = "private"

    var displayName: String {
        switch self {
        case .public: "Public"
        case .unlisted: "Unlisted"
        case .private: "Private"
        }
    }

    var icon: String {
        switch self {
        case .public: "globe"
        case .unlisted: "link"
        case .private: "lock.fill"
        }
    }
}
