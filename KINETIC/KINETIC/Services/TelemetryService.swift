import Foundation
import Supabase

struct TelemetryService {
    static let shared = TelemetryService()

    private var client: SupabaseClient? { SupabaseManager.shared.client }

    func fetchTelemetry(sessionId: UUID) async throws -> DBTelemetryData? {
        guard let client else { throw ServiceError.notConfigured }
        let results: [DBTelemetryData] = try await client
            .from("telemetry_data")
            .select()
            .eq("session_id", value: sessionId.uuidString)
            .limit(1)
            .execute()
            .value

        return results.first
    }

    func saveTelemetry(_ data: DBTelemetryData) async throws {
        guard let client else { throw ServiceError.notConfigured }
        try await client
            .from("telemetry_data")
            .upsert(data, onConflict: "session_id")
            .execute()
    }
}
