import SwiftUI

struct ShareActivityView: View {
    let sessionId: UUID

    var body: some View {
        Text("Share Activity")
            .navigationTitle("Share")
    }
}

#Preview {
    NavigationStack {
        ShareActivityView(sessionId: UUID())
    }
}
