import SwiftUI

struct MainTabView: View {
    @State private var tabCoordinator = MainTabCoordinator()
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        VStack(spacing: 0) {
            // Content
            ZStack {
                // Feed tab hidden until ready
                // NavigationStack(path: $tabCoordinator.feedPath) {
                //     FeedView()
                //         .navigationDestination(for: FeedRoute.self) { route in
                //             switch route {
                //             case .postDetail(let post):
                //                 PostDetailView(post: post)
                //             case .newPost:
                //                 NewPostView()
                //             case .clips:
                //                 ClipsListView()
                //             }
                //         }
                // }
                // .opacity(tabCoordinator.selectedTab == .feed ? 1 : 0)

                NavigationStack(path: $tabCoordinator.recordPath) {
                    RecordView()
                }
                .opacity(tabCoordinator.selectedTab == .record ? 1 : 0)

                NavigationStack(path: $tabCoordinator.historyPath) {
                    HistoryView()
                }
                .opacity(tabCoordinator.selectedTab == .history ? 1 : 0)

                NavigationStack(path: $tabCoordinator.settingsPath) {
                    SettingsView()
                }
                .opacity(tabCoordinator.selectedTab == .settings ? 1 : 0)
            }

            // Tab Bar
            KineticTabBar(selectedTab: $tabCoordinator.selectedTab)
        }
        .environment(tabCoordinator)
        .id(languageManager.refreshId)
    }
}

// MARK: - Custom Tab Bar

struct KineticTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                VStack(spacing: 6) {
                    Image(tab.icon(selected: selectedTab == tab))
                        .renderingMode(.template)

                    Text(tab.title)
                        .font(.inter(11, weight: selectedTab == tab ? .semibold : .regular))
                }
                .foregroundStyle(selectedTab == tab ? Color(hex: 0xA73400) : Color(hex: 0x6D6D78))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.08), radius: 12, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Tab Config

extension MainTab {
    var title: String {
        switch self {
        // case .feed: LanguageManager.shared.localizedString("tab.feed")
        case .record: LanguageManager.shared.localizedString("tab.record")
        case .history: LanguageManager.shared.localizedString("tab.history")
        case .settings: LanguageManager.shared.localizedString("tab.settings")
        }
    }

    func icon(selected: Bool) -> String {
        switch self {
        // case .feed: selected ? "feedSelected" : "feed"
        case .record: selected ? "recordSelected" : "record"
        case .history: selected ? "historySelected" : "history"
        case .settings: selected ? "settingsSelected" : "settings"
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppCoordinator())
        .environment(LanguageManager.shared)
}
