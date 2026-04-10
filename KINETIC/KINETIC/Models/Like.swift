import Foundation

struct Like: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let postId: UUID
    let createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        postId: UUID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.postId = postId
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case createdAt = "created_at"
    }
}
