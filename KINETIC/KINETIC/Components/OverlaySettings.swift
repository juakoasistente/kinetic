import Foundation

/// Controls which data elements are visible in the recording overlay.
/// Persisted locally via UserDefaults. Singleton.
@Observable
final class OverlaySettings {
    static let shared = OverlaySettings()

    var showSpeed: Bool {
        didSet { save() }
    }
    var showMaxSpeed: Bool {
        didSet { save() }
    }
    var showAvgSpeed: Bool {
        didSet { save() }
    }
    var showDistance: Bool {
        didSet { save() }
    }
    var showTime: Bool {
        didSet { save() }
    }
    var showMiniMap: Bool {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard
    private let prefix = "overlay_"

    private init() {
        showSpeed = defaults.object(forKey: "overlay_showSpeed") as? Bool ?? true
        showMaxSpeed = defaults.object(forKey: "overlay_showMaxSpeed") as? Bool ?? true
        showAvgSpeed = defaults.object(forKey: "overlay_showAvgSpeed") as? Bool ?? true
        showDistance = defaults.object(forKey: "overlay_showDistance") as? Bool ?? true
        showTime = defaults.object(forKey: "overlay_showTime") as? Bool ?? true
        showMiniMap = defaults.object(forKey: "overlay_showMiniMap") as? Bool ?? true
    }

    private func save() {
        defaults.set(showSpeed, forKey: "overlay_showSpeed")
        defaults.set(showMaxSpeed, forKey: "overlay_showMaxSpeed")
        defaults.set(showAvgSpeed, forKey: "overlay_showAvgSpeed")
        defaults.set(showDistance, forKey: "overlay_showDistance")
        defaults.set(showTime, forKey: "overlay_showTime")
        defaults.set(showMiniMap, forKey: "overlay_showMiniMap")
    }
}
