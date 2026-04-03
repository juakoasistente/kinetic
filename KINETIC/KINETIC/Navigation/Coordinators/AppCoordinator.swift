import SwiftUI

enum AppRoute: Hashable {
    case splash
    case auth
    case main
}

@Observable
final class AppCoordinator {
    var currentRoute: AppRoute = .splash

    func showAuth() {
        currentRoute = .auth
    }

    func showMain() {
        currentRoute = .main
    }

    func showSplash() {
        currentRoute = .splash
    }
}
