import SwiftUI

struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @Environment(MainTabCoordinator.self) private var tabCoordinator

    init(viewModel: HistoryViewModel = HistoryViewModel()) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.sessions.isEmpty {
                SpinningView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.fog)
            } else if viewModel.filteredSessions.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "video",
                    badge: "No Data",
                    title: LanguageManager.shared.localizedString("history.empty.title"),
                    subtitle: LanguageManager.shared.localizedString("history.empty.subtitle"),
                    buttonTitle: LanguageManager.shared.localizedString("history.empty.button"),
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
            case .player(let session):
                PlayerView(session: session)
            case .share(let sessionId):
                ShareActivityView(sessionId: sessionId)
            }
        }
        .task {
            await viewModel.loadSessions()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var historyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text(localized: "history.title")
                    .font(.inter(32, weight: .extraBold))
                    .foregroundStyle(.coal)
                    .padding(.top, 24)

                Text(localized: "history.subtitle")
                    .font(.inter(15, weight: .regular))
                    .foregroundStyle(.gravel)
                    .padding(.top, 6)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gravel)
                    TextField(LanguageManager.shared.localizedString("history.searchPlaceholder"), text: $viewModel.searchText)
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
                        NavigationLink(value: HistoryRoute.player(session: session)) {
                            SessionRow(session: session)
                                .contentShape(Rectangle())
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
        .refreshable {
            await viewModel.loadSessions()
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
