import Foundation

struct Profile: Codable, Identifiable, Sendable {
    let id: UUID
    var nickname: String
    var bio: String
    var avatarUrl: String?
    var tier: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        nickname: String = "",
        bio: String = "",
        avatarUrl: String? = nil,
        tier: String = "free",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.nickname = nickname
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.tier = tier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case bio
        case avatarUrl = "avatar_url"
        case tier
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
