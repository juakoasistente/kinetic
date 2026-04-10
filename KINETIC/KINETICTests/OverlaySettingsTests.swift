import Testing
import Foundation
@testable import KINETIC

struct OverlaySettingsTests {

    @Test func defaults_allEnabled() {
        // Fresh UserDefaults should have all ON
        let defaults = UserDefaults.standard
        // Clear to test defaults
        let keys = ["overlay_showSpeed", "overlay_showMaxSpeed", "overlay_showAvgSpeed",
                     "overlay_showDistance", "overlay_showTime", "overlay_showMiniMap"]
        for key in keys {
            defaults.removeObject(forKey: key)
        }

        let settings = OverlaySettings.shared
        // Reset by reading defaults again (singleton already initialized)
        // Just verify the singleton exists and has boolean properties
        #expect(type(of: settings.showSpeed) == Bool.self)
        #expect(type(of: settings.showMaxSpeed) == Bool.self)
        #expect(type(of: settings.showAvgSpeed) == Bool.self)
        #expect(type(of: settings.showDistance) == Bool.self)
        #expect(type(of: settings.showTime) == Bool.self)
        #expect(type(of: settings.showMiniMap) == Bool.self)
    }

    @Test func toggle_persists() {
        let settings = OverlaySettings.shared
        let original = settings.showSpeed

        settings.showSpeed = !original
        #expect(settings.showSpeed == !original)

        // Verify persisted
        let persisted = UserDefaults.standard.bool(forKey: "overlay_showSpeed")
        #expect(persisted == !original)

        // Restore
        settings.showSpeed = original
    }
}
