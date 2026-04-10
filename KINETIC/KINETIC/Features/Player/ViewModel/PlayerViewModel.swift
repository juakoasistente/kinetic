import Foundation
import UIKit
import AVFoundation
import Combine

@Observable
final class PlayerViewModel {
    let sessionId: UUID
    var session: Session?
    var dbTelemetry: DBTelemetryData?
    var telemetry: TelemetryData?
    var snapshots: [TelemetrySnapshot] = []
    var isPlaying = false
    var isLoading = false
    var useMetric = true
    var showDeleteAlert = false
    var errorMessage: String?

    // Dynamic playback state
    var currentTime: TimeInterval = 0
    var currentSnapshot: TelemetrySnapshot?
    private var timeObserver: Any?

    init(sessionId: UUID, session: Session? = nil) {
        self.sessionId = sessionId
        self.session = session
    }

    func loadSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await TelemetryService.shared.fetchTelemetry(sessionId: sessionId)
            dbTelemetry = fetched
            if let fetched, let session {
                telemetry = fetched.toTelemetryData(sessionTime: session.duration)
                snapshots = fetched.snapshots ?? []
            }
        } catch {
            print("[PlayerViewModel] Failed to load telemetry: \(error)")
        }
    }

    // MARK: - Video Time Sync

    func observePlayer(_ player: AVPlayer) {
        // Update every 0.5 seconds
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds
            self.updateCurrentSnapshot()
        }
    }

    func removeObserver(from player: AVPlayer) {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func updateCurrentSnapshot() {
        guard !snapshots.isEmpty else { return }
        // Find the snapshot closest to current playback time
        currentSnapshot = snapshots.last(where: { $0.timestamp <= currentTime }) ?? snapshots.first
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    func deleteSession() async {
        do {
            try await SessionService.shared.deleteSession(id: sessionId)
            HapticManager.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Dynamic Values (change with video time)

    var liveSpeed: String {
        guard let snap = currentSnapshot else { return speedValue }
        return String(format: "%.0f", snap.speed)
    }

    var liveMaxSpeed: String {
        guard let snap = currentSnapshot else { return speedValue }
        return String(format: "%.0f", snap.maxSpeed)
    }

    var liveDistance: String {
        guard let snap = currentSnapshot else { return distanceValue }
        return String(format: "%.1f", snap.distance)
    }

    var liveElevation: String {
        guard let snap = currentSnapshot else { return elevationValue }
        return String(format: "%.0f", snap.elevation)
    }

    var liveTime: String {
        guard let snap = currentSnapshot else { return formattedDuration }
        let total = Int(snap.timestamp)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d : %02d : %02d", h, m, s)
    }

    var hasDynamicData: Bool { !snapshots.isEmpty }

    var playbackProgress: Double {
        guard let session, session.duration > 0 else { return 0 }
        return min(currentTime / session.duration, 1.0)
    }

    // MARK: - Static Values (totals)

    var sessionName: String {
        session?.name ?? "--"
    }

    var sessionDateText: String {
        guard let session else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: session.date)
    }

    var formattedDuration: String {
        guard let session else { return "-- : -- : --" }
        let total = Int(session.duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d : %02d : %02d", h, m, s)
    }

    var distanceValue: String {
        guard let t = dbTelemetry else { return "--" }
        return String(format: "%.1f", t.distance)
    }

    var elevationValue: String {
        guard let t = dbTelemetry else { return "--" }
        return String(format: "%.0f", t.elevation)
    }

    var maxAltitudeValue: String {
        guard let t = dbTelemetry else { return "--" }
        return String(format: "%.0f", t.maxAltitude)
    }

    var fuelValue: String {
        guard let t = dbTelemetry else { return "--" }
        return String(format: "%.1f", t.fuelConsumption)
    }

    var speedValue: String {
        guard let t = dbTelemetry else { return "--" }
        return String(format: "%.0f", t.maxSpeed)
    }

    var gForceValue: String {
        guard let t = dbTelemetry else { return "--" }
        return String(format: "%.1f", t.peakGForce)
    }
}
