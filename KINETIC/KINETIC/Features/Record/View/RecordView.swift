import SwiftUI

struct RecordView: View {
    var body: some View {
        Text("Record")
            .navigationTitle("Record")
    }
}

#Preview {
    NavigationStack {
        RecordView()
    }
}
