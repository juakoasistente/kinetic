import SwiftUI

struct AppRootView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        Group {
            switch coordinator.currentRoute {
            case .splash:
                SplashView(coordinator: coordinator)
            case .auth:
                AuthView(coordinator: coordinator)
            case .main:
                MainTabView()
            }
        }
        .environment(coordinator)
    }
}
