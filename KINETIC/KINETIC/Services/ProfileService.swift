import Foundation
import Supabase

struct ProfileService {
    static let shared = ProfileService()

    private var client: SupabaseClient? { SupabaseManager.shared.client }

    func fetchProfile(userId: UUID) async throws -> Profile {
        guard let client else { throw ServiceError.notConfigured }
        return try await client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func updateProfile(_ profile: Profile) async throws {
        guard let client else { throw ServiceError.notConfigured }
        try await client
            .from("profiles")
            .update(profile)
            .eq("id", value: profile.id.uuidString)
            .execute()
    }

    func uploadAvatar(userId: UUID, imageData: Data) async throws -> String {
        guard let client else { throw ServiceError.notConfigured }
        let path = "\(userId.uuidString)/avatar.jpg"

        try await client.storage
            .from("avatars")
            .upload(path: path, file: imageData, options: .init(contentType: "image/jpeg", upsert: true))

        let publicURL = try client.storage
            .from("avatars")
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }
}

enum ServiceError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        "Supabase not configured"
    }
}
