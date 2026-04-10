import Foundation
import Supabase

struct ClipService {
    static let shared = ClipService()

    private var client: SupabaseClient? { SupabaseManager.shared.client }

    func fetchClips(userId: UUID) async throws -> [Clip] {
        guard let client else { throw ServiceError.notConfigured }
        return try await client
            .from("clips")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createClip(_ clip: Clip) async throws {
        guard let client else { throw ServiceError.notConfigured }

        struct InsertClip: Encodable {
            let userId: UUID
            let sessionId: UUID?
            let title: String
            let videoUrl: String
            let thumbnailUrl: String?

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case sessionId = "session_id"
                case title
                case videoUrl = "video_url"
                case thumbnailUrl = "thumbnail_url"
            }
        }

        let insert = InsertClip(
            userId: clip.userId,
            sessionId: clip.sessionId,
            title: clip.title,
            videoUrl: clip.videoUrl,
            thumbnailUrl: clip.thumbnailUrl
        )

        try await client
            .from("clips")
            .insert(insert)
            .execute()
    }

    func deleteClip(id: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        try await client
            .from("clips")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func updateClipTitle(id: UUID, title: String) async throws {
        guard let client else { throw ServiceError.notConfigured }
        try await client
            .from("clips")
            .update(["title": title])
            .eq("id", value: id.uuidString)
            .execute()
    }
}
