import SwiftUI
import AuthenticationServices

struct AuthView: View {
    let coordinator: AppCoordinator
    @State private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            // Background image
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Dark overlay for readability
            Color.white.opacity(0.10)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text("KINETIC")
                    .font(.inter(32, weight: .black))
                    .foregroundStyle(Color(hex: 0xA73400))

                Text(localized: "auth.title")
                    .font(.inter(58, weight: .extraBold))
                    .foregroundStyle(Color(hex: 0x1A1C1E))
                    .padding(.top, 12)

                Text(localized: "auth.subtitle")
                    .font(.inter(24, weight: .regular))
                    .foregroundStyle(Color(hex: 0x5F5E5E))
                    .padding(.top, 8)

                Spacer()

                // Apple Sign In
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        await viewModel.handleAppleSignIn(result: result)
                        if SupabaseManager.shared.isAuthenticated {
                            coordinator.showMain()
                        }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Loading indicator
                if viewModel.isLoading {
                    SpinningView()
                        .scaleEffect(0.5)
                        .padding(.top, 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }

                Spacer()

                // Terms
                VStack(alignment: .leading, spacing: 2) {
                    Text(localized: "auth.termsPrefix")
                        .font(.inter(10, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(Color(hex: 0x5F5E5E))

                    HStack(spacing: 4) {
                        Text(localized: "auth.termsOfService")
                            .font(.inter(10, weight: .medium))
                            .foregroundStyle(Color(hex: 0xA73400))
                        Text(localized: "auth.and")
                            .font(.inter(10, weight: .medium))
                            .foregroundStyle(Color(hex: 0x5F5E5E))
                        Text(localized: "auth.privacyPolicy")
                            .font(.inter(10, weight: .medium))
                            .foregroundStyle(Color(hex: 0xA73400))
                        Text(".")
                            .font(.inter(10, weight: .medium))
                            .foregroundStyle(Color(hex: 0x5F5E5E))
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .alert(LanguageManager.shared.localizedString("alert.error"), isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(LanguageManager.shared.localizedString("alert.ok")) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    AuthView(coordinator: AppCoordinator())
}
