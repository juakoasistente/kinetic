import SwiftUI
import CoreLocation

enum MainTab: String, CaseIterable {
    case feed
    case record
    case history
    case settings
}

@Observable
final class MainTabCoordinator {
    var selectedTab: MainTab = .feed
    var feedPath: [FeedRoute] = []
    var recordPath: [RecordRoute] = []
    var historyPath: [HistoryRoute] = []
    var settingsPath: [SettingsRoute] = []
}

enum FeedRoute: Hashable {
    case postDetail(Post)
    case newPost
    case clips
}

enum RecordRoute: Hashable {
    case trackingConfig
    case countdown
    case recording
    case summary(sessionId: UUID)
    case routeSetup
    case waitingForStart(startCoordinate: CLLocationCoordinate2D, endCoordinate: CLLocationCoordinate2D)
    case scheduledRecording(endCoordinate: CLLocationCoordinate2D)
}

enum HistoryRoute: Hashable {
}

enum SettingsRoute: Hashable {
    case editProfile
    case language
    case terms
    case privacy
}

extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
