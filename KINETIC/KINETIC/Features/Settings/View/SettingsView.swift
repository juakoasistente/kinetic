import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .editProfile:
                    EditProfileView()
                case .language:
                    LanguageSelectorView()
                }
            }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
