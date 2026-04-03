import Foundation

@Observable
final class AuthViewModel {
    var isLoading = false
    var errorMessage: String?

    func signInWithApple() async {
        isLoading = true
        defer { isLoading = false }
        // TODO: Implement Apple Sign In
    }

    func signInWithGoogle() async {
        isLoading = true
        defer { isLoading = false }
        // TODO: Implement Google Sign In
    }
}
