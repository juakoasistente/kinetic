import SwiftUI

enum MainTab: String, CaseIterable {
    case record
    case history
    case settings
}

@Observable
final class MainTabCoordinator {
    var selectedTab: MainTab = .record
    var feedPath: [FeedRoute] = []
    var recordPath: [RecordRoute] = []
    var historyPath: [HistoryRoute] = []
    var settingsPath: [SettingsRoute] = []
}

enum FeedRoute: Hashable {
    case detail(activityId: String)
}

enum RecordRoute: Hashable {
    case trackingConfig
    case countdown
    case recording
    case summary(sessionId: String)
}

enum HistoryRoute: Hashable {
    case player(sessionId: String)
    case share(sessionId: String)
}

enum SettingsRoute: Hashable {
    case editProfile
    case language
    case terms
    case privacy
}
