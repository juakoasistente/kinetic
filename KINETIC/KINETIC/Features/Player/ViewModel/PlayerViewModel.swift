import Foundation

@Observable
final class PlayerViewModel {
    let sessionId: String
    var telemetry: TelemetryData?
    var isPlaying = false
    var useMetric = true

    init(sessionId: String) {
        self.sessionId = sessionId
    }

    func loadSession() async {
        // TODO: Load session data and telemetry
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    func deleteSession() async {
        // TODO: Delete session
    }

    func downloadSession() async {
        // TODO: Download session
    }
}
