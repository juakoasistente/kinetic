import Foundation
import Supabase

struct SocialService {
    static let shared = SocialService()

    private var client: SupabaseClient? { SupabaseManager.shared.client }

    // MARK: - Likes

    func likePost(postId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SupabaseManager.shared.currentUserId else { throw ServiceError.notConfigured }

        struct InsertLike: Encodable {
            let userId: UUID
            let postId: UUID

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case postId = "post_id"
            }
        }

        try await client
            .from("likes")
            .insert(InsertLike(userId: userId, postId: postId))
            .execute()
    }

    func unlikePost(postId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SupabaseManager.shared.currentUserId else { throw ServiceError.notConfigured }
        try await client
            .from("likes")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("post_id", value: postId.uuidString)
            .execute()
    }

    func isPostLiked(postId: UUID) async throws -> Bool {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SupabaseManager.shared.currentUserId else { throw ServiceError.notConfigured }
        let count: Int = try await client
            .from("likes")
            .select("*", head: true, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .eq("post_id", value: postId.uuidString)
            .execute()
            .count ?? 0
        return count > 0
    }

    func likesCount(postId: UUID) async throws -> Int {
        guard let client else { throw ServiceError.notConfigured }
        return try await client
            .from("likes")
            .select("*", head: true, count: .exact)
            .eq("post_id", value: postId.uuidString)
            .execute()
            .count ?? 0
    }

    // MARK: - Comments

    func fetchComments(postId: UUID) async throws -> [Comment] {
        guard let client else { throw ServiceError.notConfigured }
        return try await client
            .from("comments")
            .select("*, profiles(*)")
            .eq("post_id", value: postId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func addComment(postId: UUID, content: String) async throws -> Comment {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SupabaseManager.shared.currentUserId else { throw ServiceError.notConfigured }

        struct InsertComment: Encodable {
            let userId: UUID
            let postId: UUID
            let content: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case postId = "post_id"
                case content
            }
        }

        return try await client
            .from("comments")
            .insert(InsertComment(userId: userId, postId: postId, content: content))
            .select("*, profiles(*)")
            .single()
            .execute()
            .value
    }

    func deleteComment(id: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        try await client
            .from("comments")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Bookmarks

    func bookmarkPost(postId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SupabaseManager.shared.currentUserId else { throw ServiceError.notConfigured }

        struct InsertBookmark: Encodable {
            let userId: UUID
            let postId: UUID

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case postId = "post_id"
            }
        }

        try await client
            .from("bookmarks")
            .insert(InsertBookmark(userId: userId, postId: postId))
            .execute()
    }

    func unbookmarkPost(postId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SupabaseManager.shared.currentUserId else { throw ServiceError.notConfigured }
        try await client
            .from("bookmarks")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("post_id", value: postId.uuidString)
            .execute()
    }
}
