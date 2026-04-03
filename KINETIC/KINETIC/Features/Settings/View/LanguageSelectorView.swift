import SwiftUI

struct LanguageSelectorView: View {
    var body: some View {
        Text("Language Selector")
            .navigationTitle("Language")
    }
}

#Preview {
    NavigationStack {
        LanguageSelectorView()
    }
}
