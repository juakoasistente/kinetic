import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        List(viewModel.filteredSessions) { session in
            NavigationLink(value: HistoryRoute.player(sessionId: session.id)) {
                SessionRow(session: session)
            }
        }
        .listStyle(.plain)
        .searchable(text: $viewModel.searchText, prompt: "Search routes, vehicles, or dates...")
        .navigationTitle("History")
        .navigationDestination(for: HistoryRoute.self) { route in
            switch route {
            case .player(let sessionId):
                PlayerView(sessionId: sessionId)
            case .share(let sessionId):
                ShareActivityView(sessionId: sessionId)
            }
        }
        .task {
            await viewModel.loadSessions()
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
