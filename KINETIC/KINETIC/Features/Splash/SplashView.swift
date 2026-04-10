import SwiftUI

struct SplashView: View {
    let coordinator: AppCoordinator

    var body: some View {
        Image("splashscreen")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .task {
                let hasSession = await SupabaseManager.shared.restoreSession()
                try? await Task.sleep(for: .seconds(1.5))
                if hasSession {
                    coordinator.showMain()
                } else if !coordinator.hasCompletedOnboarding {
                    coordinator.showOnboarding()
                } else {
                    coordinator.showAuth()
                }
            }
    }
}

#Preview {
    SplashView(coordinator: AppCoordinator())
}

