import Foundation
import Supabase
import AuthenticationServices

@Observable
final class SupabaseManager {
    static let shared = SupabaseManager()

    private static let supabaseURL = "https://oanvmzfeitknwoxrtyjp.supabase.co"
    private static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9hbnZtemZlaXRrbndveHJ0eWpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MDUyNTksImV4cCI6MjA5MDk4MTI1OX0.yRLSLwfSWjJimyBlwukv6_RWvZlTjrWm7FiFp0suyEg"

    let client: SupabaseClient?
    var isConfigured: Bool { client != nil }

    var currentUser: User? { client?.auth.currentUser }
    var currentUserId: UUID? { currentUser?.id }
    var isAuthenticated: Bool { currentUser != nil }

    private init() {
        if Self.supabaseURL != "YOUR_SUPABASE_URL",
           let url = URL(string: Self.supabaseURL) {
            client = SupabaseClient(supabaseURL: url, supabaseKey: Self.supabaseKey)
        } else {
            client = nil
            print("[SupabaseManager] Not configured — running in offline mode")
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let client else { return }
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.missingToken
        }

        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async throws {
        guard let client else { return }
        try await client.auth.signInWithOAuth(provider: .google, redirectTo: URL(string: "kinetic://auth/callback"))
    }

    // MARK: - Sign Out

    func signOut() async throws {
        guard let client else { return }
        try await client.auth.signOut()
    }

    // MARK: - Session

    func restoreSession() async -> Bool {
        guard let client else { return false }
        do {
            _ = try await client.auth.session
            return true
        } catch {
            return false
        }
    }
}

enum AuthError: LocalizedError {
    case missingToken

    var errorDescription: String? {
        switch self {
        case .missingToken: "Missing identity token from Apple"
        }
    }
}
