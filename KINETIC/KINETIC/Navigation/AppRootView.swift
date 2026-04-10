import SwiftUI
import Supabase

struct AppRootView: View {
    @State private var coordinator = AppCoordinator()
    @State private var mainViewId = UUID()

    var body: some View {
        Group {
            switch coordinator.currentRoute {
            case .splash:
                SplashView(coordinator: coordinator)
                    .transition(.opacity)
            case .onboarding:
                OnboardingView {
                    coordinator.completeOnboarding()
                }
                .transition(.opacity)
            case .auth:
                AuthView(coordinator: coordinator)
                    .transition(.opacity)
            case .main:
                MainTabView()
                    .id(mainViewId)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: coordinator.currentRoute)
        .environment(coordinator)
        .onChange(of: coordinator.currentRoute) { _, newRoute in
            if newRoute == .main {
                mainViewId = UUID()
            }
        }
        .onOpenURL { url in
            // Handle OAuth callback (Google sign in redirect)
            Task {
                guard let client = SupabaseManager.shared.client else { return }
                try? await client.auth.session(from: url)
                if SupabaseManager.shared.isAuthenticated {
                    coordinator.showMain()
                }
            }
        }
    }
}
