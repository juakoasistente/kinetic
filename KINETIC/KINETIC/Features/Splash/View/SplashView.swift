import SwiftUI

struct SplashView: View {
    let coordinator: AppCoordinator

    var body: some View {
        Image("splashscreen")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    coordinator.showAuth()
                }
            }
    }
}

#Preview {
    SplashView(coordinator: AppCoordinator())
}

