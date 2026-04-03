import SwiftUI

struct EditProfileView: View {
    var body: some View {
        Text("Edit Profile")
            .navigationTitle("Edit Profile")
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
}
