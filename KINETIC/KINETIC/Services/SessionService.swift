import Foundation
import Supabase

struct SessionService {
    static let shared = SessionService()

    private var client: SupabaseClient? { SupabaseManager.shared.client }

    func fetchSessions(userId: UUID) async throws -> [Session] {
        guard let client else { throw ServiceError.notConfigured }
        return try await client
            .from("sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
    }

    func createSession(_ session: Session) async throws {
        guard let client else { throw ServiceError.notConfigured }
        try await client
            .from("sessions")
            .insert(session)
            .execute()
    }

    func deleteSession(id: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        try await client
            .from("sessions")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func searchSessions(userId: UUID, query: String) async throws -> [Session] {
        guard let client else { throw ServiceError.notConfigured }
        return try await client
            .from("sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .ilike("name", pattern: "%\(query)%")
            .order("date", ascending: false)
            .execute()
            .value
    }
}
