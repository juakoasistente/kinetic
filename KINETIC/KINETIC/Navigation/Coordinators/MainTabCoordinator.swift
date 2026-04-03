import SwiftUI

enum MainTab: String, CaseIterable {
    case feed
    case record
    case history
    case settings
}

@Observable
final class MainTabCoordinator {
    var selectedTab: MainTab = .history
    var feedPath: [FeedRoute] = []
    var historyPath: [HistoryRoute] = []
    var settingsPath: [SettingsRoute] = []
}

enum FeedRoute: Hashable {
    case detail(activityId: String)
}

enum HistoryRoute: Hashable {
    case player(sessionId: String)
    case share(sessionId: String)
}

enum SettingsRoute: Hashable {
    case editProfile
    case language
}
