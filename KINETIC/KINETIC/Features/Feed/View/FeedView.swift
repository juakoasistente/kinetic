import SwiftUI

struct FeedView: View {
    var body: some View {
        Text("Feed")
            .navigationTitle("Feed")
    }
}

#Preview {
    NavigationStack {
        FeedView()
    }
}
