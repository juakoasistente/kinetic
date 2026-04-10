import Foundation
import Supabase

struct SettingsService {
    static let shared = SettingsService()

    private var client: SupabaseClient? { SupabaseManager.shared.client }

    func fetchSettings(userId: UUID) async throws -> UserSettings {
        guard let client else { throw ServiceError.notConfigured }
        return try await client
            .from("user_settings")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func updateSettings(_ settings: UserSettings) async throws {
        guard let client else { throw ServiceError.notConfigured }
        try await client
            .from("user_settings")
            .update(settings)
            .eq("user_id", value: settings.userId.uuidString)
            .execute()
    }
}
