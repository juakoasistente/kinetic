import Foundation

struct PostMedia: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let postId: UUID
    var mediaUrl: String
    var mediaType: MediaType
    var sortOrder: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        postId: UUID,
        mediaUrl: String,
        mediaType: MediaType = .image,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }

    // MARK: - Mock Data

    static let mockData: [PostMedia] = {
        let mockPostId = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        return [
            PostMedia(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
                postId: mockPostId,
                mediaUrl: "https://example.com/car1.jpg",
                mediaType: .image,
                sortOrder: 0
            ),
        ]
    }()
}

// MARK: - Media Type

enum MediaType: String, Codable, Sendable {
    case image
    case video
}
