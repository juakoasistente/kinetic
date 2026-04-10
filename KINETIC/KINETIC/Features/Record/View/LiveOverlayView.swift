import SwiftUI
import Combine
import CoreLocation

// MARK: - Telemetry Overlay (previewable, reusable)

struct TelemetryOverlayView: View {
    let speed: Int
    let maxSpeed: Int
    let avgSpeed: Int
    let distance: String
    let time: String
    let isRecording: Bool
    let isPaused: Bool
    var onPause: () -> Void = {}
    var onStop: () -> Void = {}
    private let settings = OverlaySettings.shared

    var body: some View {
        VStack {
            // Top bar
            HStack {
                if isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text(LanguageManager.shared.localizedString("overlay.rec"))
                            .font(.inter(12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())
                }

                Spacer()

                if settings.showTime {
                    Text(time)
                        .font(.inter(14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()

            // Bottom telemetry
            VStack(spacing: 12) {
                // Speed — big
                if settings.showSpeed {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(speed)")
                            .font(.inter(72, weight: .black))
                            .foregroundStyle(.white)
                        Text(" \(LanguageManager.shared.localizedString("overlay.kmh"))")
                            .font(.inter(18, weight: .bold))
                            .foregroundStyle(.stravaOrange)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                }

                // Stats row
                let visibleStats = statsToShow
                if !visibleStats.isEmpty {
                    HStack(spacing: 16) {
                        ForEach(visibleStats, id: \.label) { stat in
                            overlayStatCard(label: stat.label, value: stat.value, unit: stat.unit)
                        }
                    }
                }

                // Action buttons
                HStack(spacing: 16) {
                    Button(action: onPause) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }

                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.stravaOrange)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private struct StatItem: Hashable {
        let label: String
        let value: String
        let unit: String
    }

    private var statsToShow: [StatItem] {
        var stats: [StatItem] = []
        if settings.showMaxSpeed { stats.append(StatItem(label: "MAX", value: "\(maxSpeed)", unit: "KM/H")) }
        if settings.showAvgSpeed { stats.append(StatItem(label: "AVG", value: "\(avgSpeed)", unit: "KM/H")) }
        if settings.showDistance { stats.append(StatItem(label: "DIST", value: distance, unit: "KM")) }
        return stats
    }

    private func overlayStatCard(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.inter(9, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.inter(22, weight: .bold))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.inter(9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Processing Overlay

struct ProcessingOverlayView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 24) {
                SpinningView()
                Text(LanguageManager.shared.localizedString("overlay.processingOverlay"))
                    .font(.inter(14, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Orientation Picker

enum RecordingOrientation: String, CaseIterable {
    case portrait
    case landscape

    var icon: String {
        switch self {
        case .portrait: "iphone"
        case .landscape: "iphone.landscape"
        }
    }

    var label: String {
        switch self {
        case .portrait: "Vertical"
        case .landscape: "Horizontal"
        }
    }
}

struct OrientationPickerView: View {
    @Binding var selected: RecordingOrientation
    var onConfirm: () -> Void
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            // Close button
            HStack {
                Button {
                    if let onClose {
                        onClose()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            Text(LanguageManager.shared.localizedString("overlay.chooseOrientation"))
                .font(.inter(12, weight: .bold))
                .tracking(2)
                .foregroundStyle(.gravel)

            Text(LanguageManager.shared.localizedString("overlay.orientationSubtitle"))
                .font(.inter(14, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            HStack(spacing: 24) {
                ForEach(RecordingOrientation.allCases, id: \.self) { orientation in
                    Button {
                        selected = orientation
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: orientation.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(selected == orientation ? Color.stravaOrange : .gravel)
                                .frame(width: 100, height: 100)
                                .background(selected == orientation ? Color.stravaOrange.opacity(0.15) : Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selected == orientation ? Color.stravaOrange : .clear, lineWidth: 2)
                                )

                            Text(orientation.label)
                                .font(.inter(13, weight: .semibold))
                                .foregroundStyle(selected == orientation ? .white : .gravel)
                        }
                    }
                }
            }

            Spacer()

            Button(action: onConfirm) {
                Text(LanguageManager.shared.localizedString("overlay.startRecording"))
                    .font(.inter(15, weight: .black))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.stravaOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(.black)
    }
}

// MARK: - Live Overlay View (full screen with camera)

enum OverlayState {
    case pickingOrientation
    case pickingTemplate
    case preparingCamera
    case readyToRecord
    case recording
}

struct LiveOverlayView: View {
    var onCloseAll: (() -> Void)?

    @State private var cameraManager = CameraManager()
    @State private var locationManager = LocationManager()
    @State private var elapsed: TimeInterval = 0
    @State private var isPaused = false
    @State private var showSummary = false
    @State private var trackingSummary: TrackingSummary?
    @State private var isProcessingVideo = false
    @State private var processedVideoURL: URL?
    @State private var videoLocalIdentifier: String?
    @State private var videoThumbnail: UIImage?
    @State private var orientation: RecordingOrientation = .portrait
    @State private var overlayTemplate: OverlayTemplate = .classic
    @State private var overlayState: OverlayState = .pickingOrientation
    @Environment(\.dismiss) private var dismiss

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timerStartDate: Date?

    var body: some View {
        Group {
            switch overlayState {
            case .pickingOrientation:
                OrientationPickerView(selected: $orientation, onConfirm: {
                    withAnimation { overlayState = .pickingTemplate }
                }, onClose: {
                    if let onCloseAll { onCloseAll() } else { dismiss() }
                })

            case .pickingTemplate:
                OverlayTemplatePickerView(
                    selected: $overlayTemplate,
                    onConfirm: { prepareCamera() },
                    onBack: { withAnimation { overlayState = .pickingOrientation } }
                )

            case .preparingCamera:
                // Full screen spinner while camera initializes
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 24) {
                        SpinningView()
                        Text(LanguageManager.shared.localizedString("overlay.preparingCamera"))
                            .font(.inter(14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

            case .readyToRecord, .recording:
                cameraView
            }
        }
        .onReceive(timer) { _ in
            guard overlayState == .recording, !isPaused, let start = timerStartDate else { return }
            elapsed = Date().timeIntervalSince(start)
        }
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
                    videoLocalIdentifier: videoLocalIdentifier,
                    videoThumbnail: videoThumbnail,
                    onClose: onCloseAll
                )
            }
        }
    }

    // MARK: - Camera View (preview + overlay)

    private var cameraView: some View {
        ZStack {
            CameraPreviewView(session: cameraManager.captureSession)
                .ignoresSafeArea()

            if overlayState == .readyToRecord || overlayState == .recording {
                // Show overlay always (with 0 values when not recording yet)
                switch overlayTemplate {
                case .classic:
                    TelemetryOverlayView(
                        speed: Int(locationManager.currentSpeed),
                        maxSpeed: Int(locationManager.maxSpeed),
                        avgSpeed: Int(locationManager.avgSpeed),
                        distance: String(format: "%.1f", locationManager.totalDistance),
                        time: formattedTime,
                        isRecording: cameraManager.isRecording,
                        isPaused: isPaused,
                        onPause: pauseResume,
                        onStop: { HapticManager.notification(.warning); stopEverything() }
                    )
                case .minimal:
                    MinimalOverlayView(
                        speed: Int(locationManager.currentSpeed),
                        time: formattedTime,
                        isRecording: cameraManager.isRecording,
                        onStop: { HapticManager.notification(.warning); stopEverything() }
                    )
                case .dashboard:
                    DashboardOverlayView(
                        speed: Int(locationManager.currentSpeed),
                        maxSpeed: Int(locationManager.maxSpeed),
                        avgSpeed: Int(locationManager.avgSpeed),
                        distance: String(format: "%.1f", locationManager.totalDistance),
                        time: formattedTime,
                        isRecording: cameraManager.isRecording,
                        onPause: pauseResume,
                        onStop: { HapticManager.notification(.warning); stopEverything() }
                    )
                }

                // Live mini map
                if OverlaySettings.shared.showMiniMap {
                    LiveMiniMapView(coordinates: locationManager.routeCoordinates)
                }

                // REC button overlay when ready but not yet recording
                if overlayState == .readyToRecord {
                    VStack {
                        Spacer()
                        Button {
                            startRecording()
                        } label: {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 72, height: 72)
                                    .overlay {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 4)
                                            .frame(width: 80, height: 80)
                                    }
                                Text(LanguageManager.shared.localizedString("overlay.tapToRecord"))
                                    .font(.inter(12, weight: .bold))
                                    .tracking(1)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.bottom, 120)
                    }
                }
            }

            if isProcessingVideo {
                ProcessingOverlayView()
            }
        }
        .supportedOrientations(orientation == .landscape ? .landscape : .portrait)
    }

    // MARK: - Pause/Resume

    private func pauseResume() {
        isPaused.toggle()
        if isPaused {
            locationManager.pauseTracking()
            cameraManager.stopRecording()
        } else {
            locationManager.resumeTracking()
            cameraManager.startRecording()
            timerStartDate = Date().addingTimeInterval(-elapsed)
        }
        HapticManager.impact(.medium)
    }

    // MARK: - Prepare Camera (show preview without recording)

    private func prepareCamera() {
        overlayState = .preparingCamera
        locationManager.requestPermission()

        // Run camera setup after a frame so the spinner renders first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cameraManager.configure(landscape: orientation == .landscape)
            cameraManager.start()

            // Wait for session to actually start
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { overlayState = .readyToRecord }
            }
        }
    }

    // MARK: - Start Recording

    private func startRecording() {
        locationManager.startTracking()
        cameraManager.startRecording()
        timerStartDate = Date()
        HapticManager.impact(.heavy)
        withAnimation { overlayState = .recording }
    }

    // MARK: - Stop & Process

    private func stopEverything() {
        // Force back to portrait before showing summary
        OrientationLock.shared.unlock()

        trackingSummary = locationManager.stopTracking()
        cameraManager.stopRecording()
        cameraManager.stop()

        guard let videoURL = cameraManager.recordedVideoURL, let summary = trackingSummary else {
            showSummary = true
            return
        }

        isProcessingVideo = true

        Task {
            // 1. Compose overlay onto video
            let telemetrySnapshots = generateTelemetrySnapshots(summary: summary)
            let finalURL: URL
            if let outputURL = await OverlayCompositor.composeOverlay(
                videoURL: videoURL,
                telemetrySnapshots: telemetrySnapshots
            ) {
                finalURL = outputURL
                processedVideoURL = outputURL
            } else {
                finalURL = videoURL
            }

            // 2. Save to Photos
            videoLocalIdentifier = await VideoSaveHelper.saveToPhotos(videoURL: finalURL)

            // 3. Generate thumbnail
            videoThumbnail = await VideoSaveHelper.generateThumbnail(videoURL: finalURL)

            isProcessingVideo = false
            showSummary = true
        }
    }

    private func generateTelemetrySnapshots(summary: TrackingSummary) -> [OverlayCompositor.TelemetrySnapshot] {
        let duration = Int(summary.elapsedTime)
        guard duration > 0 else { return [] }

        return (0...duration).map { second in
            let progress = Double(second) / Double(duration)
            let speed = progress * summary.maxSpeed * (0.7 + 0.3 * sin(progress * .pi))
            let dist = progress * summary.totalDistance

            return OverlayCompositor.TelemetrySnapshot(
                timestamp: TimeInterval(second),
                speed: min(speed, summary.maxSpeed),
                maxSpeed: summary.maxSpeed,
                avgSpeed: summary.avgSpeed,
                distance: dist,
                elapsed: TimeInterval(second)
            )
        }
    }

    private var formattedTime: String { formatTime(elapsed) }

    private func formatTime(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// MARK: - Previews

private let mockRouteCoords: [CLLocationCoordinate2D] = [
    CLLocationCoordinate2D(latitude: 41.385, longitude: 2.173),
    CLLocationCoordinate2D(latitude: 41.386, longitude: 2.174),
    CLLocationCoordinate2D(latitude: 41.387, longitude: 2.176),
    CLLocationCoordinate2D(latitude: 41.389, longitude: 2.175),
    CLLocationCoordinate2D(latitude: 41.390, longitude: 2.173),
    CLLocationCoordinate2D(latitude: 41.391, longitude: 2.171),
    CLLocationCoordinate2D(latitude: 41.392, longitude: 2.172),
]

private var fakeCameraBackground: some View {
    Image(systemName: "road.lanes")
        .font(.system(size: 120))
        .foregroundStyle(.gray.opacity(0.3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0x1A1A1A))
        .ignoresSafeArea()
}

#Preview("1. Orientation Picker") {
    OrientationPickerView(selected: .constant(.portrait), onConfirm: {}, onClose: {})
}

#Preview("2. Template Picker") {
    OverlayTemplatePickerView(selected: .constant(.classic), onConfirm: {}, onBack: {})
}

#Preview("3. Ready to Record") {
    ZStack {
        fakeCameraBackground
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                Text(LanguageManager.shared.localizedString("overlay.tapToRecord"))
                    .font(.inter(12, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 80)
        }
    }
}

#Preview("4a. Classic Recording") {
    ZStack {
        fakeCameraBackground
        TelemetryOverlayView(
            speed: 87, maxSpeed: 142, avgSpeed: 76,
            distance: "12.4", time: "00:14:32",
            isRecording: true, isPaused: false
        )
        LiveMiniMapView(coordinates: mockRouteCoords)
    }
}

#Preview("4b. Minimal Recording") {
    ZStack {
        fakeCameraBackground
        MinimalOverlayView(
            speed: 87, time: "00:14:32", isRecording: true
        )
        LiveMiniMapView(coordinates: mockRouteCoords)
    }
}

#Preview("4c. Dashboard Recording") {
    ZStack {
        fakeCameraBackground
        DashboardOverlayView(
            speed: 87, maxSpeed: 142, avgSpeed: 76,
            distance: "12.4", time: "14:32", isRecording: true
        )
        LiveMiniMapView(coordinates: mockRouteCoords)
    }
}

#Preview("5. Paused") {
    ZStack {
        fakeCameraBackground
        TelemetryOverlayView(
            speed: 0, maxSpeed: 142, avgSpeed: 76,
            distance: "12.4", time: "00:14:32",
            isRecording: false, isPaused: true
        )
        LiveMiniMapView(coordinates: mockRouteCoords)
    }
}

#Preview("6. Processing") {
    ProcessingOverlayView()
}
