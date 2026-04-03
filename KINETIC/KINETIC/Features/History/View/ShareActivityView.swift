import SwiftUI

struct ShareActivityView: View {
    let sessionId: String

    var body: some View {
        Text("Share Activity")
            .navigationTitle("Share")
    }
}

#Preview {
    NavigationStack {
        ShareActivityView(sessionId: "preview-1")
    }
}
