import SwiftUI

struct MainTabView: View {
    @State private var tabCoordinator = MainTabCoordinator()

    var body: some View {
        TabView(selection: $tabCoordinator.selectedTab) {
            Tab("Feed", systemImage: "circle.grid.2x2", value: .feed) {
                NavigationStack(path: $tabCoordinator.feedPath) {
                    FeedView()
                }
            }

            Tab("Record", systemImage: "record.circle", value: .record) {
                NavigationStack {
                    RecordView()
                }
            }

            Tab("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90", value: .history) {
                NavigationStack(path: $tabCoordinator.historyPath) {
                    HistoryView()
                }
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack(path: $tabCoordinator.settingsPath) {
                    SettingsView()
                }
            }
        }
        .tint(.orange)
        .environment(tabCoordinator)
    }
}
