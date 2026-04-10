import Foundation
import AuthenticationServices

@Observable
final class AuthViewModel {
    var isLoading = false
    var errorMessage: String?

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        defer { isLoading = false }

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                print("[Auth] ERROR: Invalid Apple credential type")
                errorMessage = "Something went wrong. Please try again."
                return
            }

            print("[Auth] Apple credential received")
            print("[Auth] User ID: \(credential.user)")
            print("[Auth] Email: \(credential.email ?? "hidden by Apple")")
            print("[Auth] Full name: \(credential.fullName?.givenName ?? "nil") \(credential.fullName?.familyName ?? "nil")")

            guard let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                print("[Auth] ERROR: No identity token in credential")
                errorMessage = "Something went wrong. Please try again."
                return
            }

            print("[Auth] Identity token received (\(tokenString.prefix(50))...)")
            print("[Auth] Calling Supabase signInWithIdToken...")

            do {
                try await SupabaseManager.shared.signInWithApple(credential: credential)
                print("[Auth] SUCCESS: Signed in to Supabase")
                print("[Auth] User ID: \(SupabaseManager.shared.currentUserId?.uuidString ?? "nil")")
                print("[Auth] Is authenticated: \(SupabaseManager.shared.isAuthenticated)")
            } catch {
                print("[Auth] ERROR: Supabase sign in failed: \(error)")
                print("[Auth] Error type: \(type(of: error))")
                print("[Auth] Error description: \(error.localizedDescription)")
                errorMessage = "Unable to sign in. Please try again later."
            }

        case .failure(let error):
            // User cancelled or other Apple error
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                print("[Auth] User cancelled Apple Sign In")
                // Don't show error for cancel
            } else {
                print("[Auth] Apple Sign In failed: \(error.localizedDescription)")
                errorMessage = "Unable to sign in. Please try again."
            }
        }
    }
}
