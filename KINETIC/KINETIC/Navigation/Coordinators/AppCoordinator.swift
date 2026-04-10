import SwiftUI

enum AppRoute: Hashable {
    case splash
    case onboarding
    case auth
    case main
}

@Observable
final class AppCoordinator {
    var currentRoute: AppRoute = .splash

    private static let onboardingCompletedKey = "kinetic_onboarding_completed"

    var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
    }

    func showOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentRoute = .onboarding
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
        showAuth()
    }

    func showAuth() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentRoute = .auth
        }
    }

    func showMain() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentRoute = .main
        }
    }

    func showSplash() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentRoute = .splash
        }
    }
}
