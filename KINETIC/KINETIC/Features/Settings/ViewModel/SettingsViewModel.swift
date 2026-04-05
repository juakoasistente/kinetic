import Foundation

@Observable
final class SettingsViewModel {
    var showSpeed = true
    var showDistance = true
    var showTime = false
    var showGPS = true
    var useMetric = true

    var userName = "Marcus Thorne"
    var userTier = "Gold Member • Pro Tier"

    func logout() {
        // TODO: Implement logout
    }
}
