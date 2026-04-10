import SwiftUI
import Combine
import CoreLocation

struct LiveTrackingView: View {
    var endCoordinate: CLLocationCoordinate2D? = nil
    var onCloseAll: (() -> Void)?
    @State private var locationManager = LocationManager()
    @State private var elapsed: TimeInterval = 0
    @State private var isPaused = false
    @State private var showSummary = false
    @State private var trackingSummary: TrackingSummary?
    @Environment(\.dismiss) private var dismiss

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Image("logoNavBar")
                .padding(.top, 16)

            // Speed display
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, -20)
                .padding(.top, 24)

                // Big speed
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.15), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 160
                            )
                        )
                        .frame(width: 280, height: 280)
                        .blur(radius: 20)

                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(Int(locationManager.currentSpeed))")
                            .font(.inter(100, weight: .black))
                            .italic()
                            .foregroundStyle(.white)
                        Text(" KM/H")
                            .font(.inter(20, weight: .bold))
                            .foregroundStyle(.stravaOrange)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.top, 36)
            }
            .padding(.horizontal, 20)

            Spacer()

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 1),
                GridItem(.flexible(), spacing: 1)
            ], spacing: 1) {
                statCard(label: LanguageManager.shared.localizedString("live.maxSpeed"), value: "\(Int(locationManager.maxSpeed))", unit: "KM/H")
                statCard(label: LanguageManager.shared.localizedString("live.avgSpeed"), value: "\(Int(locationManager.avgSpeed))", unit: "KM/H")
                statCard(label: LanguageManager.shared.localizedString("live.distance"), value: String(format: "%.1f", locationManager.totalDistance), unit: "KM")
                statCard(label: LanguageManager.shared.localizedString("live.time"), value: formattedTime, unit: "")
            }
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        isPaused.toggle()
                    }
                    if isPaused {
                        locationManager.pauseTracking()
                    } else {
                        locationManager.resumeTracking()
                    }
                    HapticManager.impact(.medium)
                } label: {
                    HStack(spacing: 10) {
                        Text(isPaused ? LanguageManager.shared.localizedString("tracking.resume") : LanguageManager.shared.localizedString("tracking.pause"))
                            .font(.inter(15, weight: .black))
                            .tracking(1)
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }

                Button {
                    HapticManager.notification(.warning)
                    trackingSummary = locationManager.stopTracking()
                    showSummary = true
                } label: {
                    HStack(spacing: 10) {
                        Text(localized: "tracking.stop")
                            .font(.inter(15, weight: .black))
                            .tracking(1)
                        Image("stop")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.stravaOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(.black)
        .fullScreenCover(isPresented: $showSummary) {
            if let summary = trackingSummary {
                TripSummaryView(
                    maxSpeed: "\(Int(summary.maxSpeed))",
                    avgSpeed: "\(Int(summary.avgSpeed))",
                    distance: String(format: "%.1f", summary.totalDistance),
                    time: formatTime(summary.elapsedTime),
                    durationSeconds: summary.elapsedTime,
                    distanceKm: summary.totalDistance,
                    maxSpeedValue: summary.maxSpeed,
                    avgSpeedValue: summary.avgSpeed,
                    routeCoordinates: summary.routeCoordinates,
                    telemetrySnapshots: summary.snapshots,
                    onClose: onCloseAll
                )
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.startTracking()
            if let end = endCoordinate {
                locationManager.endWaypoint = end
                locationManager.onReachedEnd = {
                    HapticManager.notification(.warning)
                    trackingSummary = locationManager.stopTracking()
                    showSummary = true
                }
            }
        }
        .onReceive(timer) { _ in
            guard !isPaused else { return }
            elapsed += 1
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        formatTime(elapsed)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func statCard(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.inter(10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.gravel)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.inter(28, weight: .bold))
                    .foregroundStyle(.white)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.inter(12, weight: .medium))
                        .foregroundStyle(.gravel)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.05))
    }
}

#Preview {
    LiveTrackingView()
}
