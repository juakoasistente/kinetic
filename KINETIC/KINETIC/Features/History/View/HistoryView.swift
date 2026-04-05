import SwiftUI

struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @Environment(MainTabCoordinator.self) private var tabCoordinator

    init(viewModel: HistoryViewModel = HistoryViewModel()) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.filteredSessions.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "video",
                    badge: "No Data",
                    title: "No Recordings Yet",
                    subtitle: "Record your first drive with telemetry to share it with the community.",
                    buttonTitle: "Start Recording",
                    action: { tabCoordinator.selectedTab = .record }
                )
            } else {
                historyContent
            }
        }
        .background(.fog)
        .toolbarBackground(.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("logoNavBar")
            }
        }
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

    private var historyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("History")
                    .font(.inter(32, weight: .extraBold))
                    .foregroundStyle(.coal)
                    .padding(.top, 24)

                Text("Review your past performance and precision routes.")
                    .font(.inter(15, weight: .regular))
                    .foregroundStyle(.gravel)
                    .padding(.top, 6)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gravel)
                    TextField("Search routes, vehicles, or dates...", text: $viewModel.searchText)
                        .font(.inter(14, weight: .regular))
                        .foregroundStyle(.coal)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.mist)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 24)

                // Sessions list
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredSessions) { session in
                        NavigationLink(value: HistoryRoute.player(sessionId: session.id)) {
                            SessionRow(session: session)
                        }
                        .buttonStyle(.plain)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview("With Sessions") {
    NavigationStack {
        HistoryView(viewModel: .preview)
    }
    .environment(MainTabCoordinator())
}

#Preview("Empty") {
    NavigationStack {
        HistoryView()
    }
    .environment(MainTabCoordinator())
}
