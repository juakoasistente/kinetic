import Foundation
import Supabase

struct PostService {
    static let shared = PostService()

    private var client: SupabaseClient? { SupabaseManager.shared.client }

    // MARK: - Feed

    func fetchFeed(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        guard let client else { throw ServiceError.notConfigured }
        return try await client
            .from("posts")
            .select("""
                *,
                profiles(*),
                sessions(*),
                post_media(*)
            """)
            .eq("visibility", value: "public")
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    // MARK: - CRUD

    func fetchPost(id: UUID) async throws -> Post {
        guard let client else { throw ServiceError.notConfigured }
        return try await client
            .from("posts")
            .select("""
                *,
                profiles(*),
                sessions(*),
                post_media(*)
            """)
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchUserPosts(userId: UUID) async throws -> [Post] {
        guard let client else { throw ServiceError.notConfigured }
        return try await client
            .from("posts")
            .select("""
                *,
                profiles(*),
                sessions(*),
                post_media(*)
            """)
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createPost(_ post: Post) async throws -> Post {
        guard let client else { throw ServiceError.notConfigured }

        struct InsertPost: Encodable {
            let userId: UUID
            let sessionId: UUID?
            let description: String
            let visibility: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case sessionId = "session_id"
                case description
                case visibility
            }
        }

        let insert = InsertPost(
            userId: post.userId,
            sessionId: post.sessionId,
            description: post.description,
            visibility: post.visibility.rawValue
        )

        return try await client
            .from("posts")
            .insert(insert)
            .select("""
                *,
                profiles(*),
                sessions(*),
                post_media(*)
            """)
            .single()
            .execute()
            .value
    }

    func deletePost(id: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        try await client
            .from("posts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Media

    func addMedia(postId: UUID, mediaUrl: String, mediaType: MediaType, sortOrder: Int) async throws {
        guard let client else { throw ServiceError.notConfigured }

        struct InsertMedia: Encodable {
            let postId: UUID
            let mediaUrl: String
            let mediaType: String
            let sortOrder: Int

            enum CodingKeys: String, CodingKey {
                case postId = "post_id"
                case mediaUrl = "media_url"
                case mediaType = "media_type"
                case sortOrder = "sort_order"
            }
        }

        let insert = InsertMedia(
            postId: postId,
            mediaUrl: mediaUrl,
            mediaType: mediaType.rawValue,
            sortOrder: sortOrder
        )

        try await client
            .from("post_media")
            .insert(insert)
            .execute()
    }

    func uploadPostImage(postId: UUID, imageData: Data, index: Int) async throws -> String {
        guard let client else { throw ServiceError.notConfigured }
        let path = "\(postId.uuidString.lowercased())/\(index).jpg"
        try await client.storage
            .from("post-media")
            .upload(path, data: imageData, options: .init(contentType: "image/jpeg", upsert: true))
        let publicUrl = try client.storage
            .from("post-media")
            .getPublicURL(path: path)
        return publicUrl.absoluteString
    }

    func uploadPostVideo(postId: UUID, videoData: Data, index: Int) async throws -> String {
        guard let client else { throw ServiceError.notConfigured }
        let path = "\(postId.uuidString.lowercased())/\(index).mov"
        try await client.storage
            .from("post-media")
            .upload(path, data: videoData, options: .init(contentType: "video/quicktime", upsert: true))
        let publicUrl = try client.storage
            .from("post-media")
            .getPublicURL(path: path)
        return publicUrl.absoluteString
    }
}
