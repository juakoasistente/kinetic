import SwiftUI
import MapKit
import PhotosUI
import AVFoundation
import Supabase

struct GPXPreviewView: View {
    let routeName: String
    let coordinates: [CLLocationCoordinate2D]
    let gpxRoute: GPXRoute?
    var onClose: () -> Void

    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var videoURL: URL?
    @State private var videoDuration: TimeInterval = 0
    @State private var selectedTemplate: OverlayTemplate = .classic
    @State private var isProcessing = false
    @State private var processedVideoURL: URL?
    @State private var showShareSheet = false
    @State private var isSaving = false
    @State private var didSave = false
    @State private var step: GPXStep = .preview

    enum GPXStep {
        case preview        // Show route on map
        case selectVideo    // Pick video
        case selectTemplate // Choose overlay style
        case processing     // Composing
        case done           // Ready to share/save
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    if step == .preview { onClose() }
                    else { withAnimation { step = previousStep } }
                }) {
                    Image(systemName: step == .preview ? "xmark" : "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("KINETIC")
                    .font(.inter(16, weight: .black))
                    .foregroundStyle(.stravaOrange)

                Spacer()

                Image(systemName: "xmark").opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.black)

            // Content
            switch step {
            case .preview:
                routePreview
            case .selectVideo:
                videoSelection
            case .selectTemplate:
                templateSelection
            case .processing:
                processingView
            case .done:
                doneView
            }
        }
        .background(.black)
    }

    private var previousStep: GPXStep {
        switch step {
        case .selectVideo: .preview
        case .selectTemplate: .selectVideo
        default: .preview
        }
    }

    // MARK: - Step 1: Route Preview

    private var routePreview: some View {
        VStack(spacing: 0) {
            // Map
            if coordinates.count >= 2 {
                Map(initialPosition: .region(regionForRoute)) {
                    MapPolyline(coordinates: coordinates)
                        .stroke(KineticMapStyle.routeColor, lineWidth: KineticMapStyle.routeLineWidth)
                    if let first = coordinates.first {
                        Annotation("", coordinate: first) {
                            Circle().fill(.green).frame(width: 12, height: 12)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                    if let last = coordinates.last {
                        Annotation("", coordinate: last) {
                            Circle().fill(.red).frame(width: 12, height: 12)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                }
                .mapStyle(KineticMapStyle.route)
                .mapControlVisibility(.hidden)
            }

            // Info
            VStack(spacing: 16) {
                Text(routeName.uppercased())
                    .font(.inter(20, weight: .black))
                    .foregroundStyle(.white)

                HStack(spacing: 24) {
                    statLabel(label: "POINTS", value: "\(coordinates.count)")
                    statLabel(label: "DISTANCE", value: formattedDistance)
                }

                Button {
                    withAnimation { step = .selectVideo }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("SELECT VIDEO")
                            .font(.inter(15, weight: .black))
                            .tracking(1)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.stravaOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
            .background(.black)
        }
    }

    // MARK: - Step 2: Video Selection

    private var videoSelection: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "video.fill")
                .font(.system(size: 48))
                .foregroundStyle(.stravaOrange.opacity(0.5))

            Text("SELECT VIDEO")
                .font(.inter(12, weight: .bold))
                .tracking(2)
                .foregroundStyle(.gravel)

            Text("Choose the video recorded during this route")
                .font(.inter(14, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 16, weight: .bold))
                    Text("CHOOSE FROM GALLERY")
                        .font(.inter(15, weight: .black))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.stravaOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .onChange(of: selectedVideoItem) { _, item in
            guard let item else { return }
            Task {
                if let url = try? await loadVideo(from: item) {
                    videoURL = url
                    let asset = AVURLAsset(url: url)
                    if let duration = try? await asset.load(.duration) {
                        videoDuration = duration.seconds
                    }
                    withAnimation { step = .selectTemplate }
                }
            }
        }
    }

    // MARK: - Step 3: Template Selection

    private var templateSelection: some View {
        VStack(spacing: 24) {
            Spacer()

            OverlayTemplatePickerView(
                selected: $selectedTemplate,
                onConfirm: { processVideo() },
                onBack: { withAnimation { step = .selectVideo } }
            )
        }
    }

    // MARK: - Step 4: Processing

    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()
            SpinningView()
            Text(LanguageManager.shared.localizedString("overlay.processingOverlay"))
                .font(.inter(14, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
        }
    }

    // MARK: - Step 5: Done

    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.stravaOrange)

            Text("VIDEO READY")
                .font(.inter(16, weight: .black))
                .tracking(2)
                .foregroundStyle(.white)

            Spacer()

            // Share
            Button {
                if let url = processedVideoURL {
                    showShareSheet = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .bold))
                    Text(LanguageManager.shared.localizedString("share.share"))
                        .font(.inter(15, weight: .black))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.stravaOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)

            // Save to History
            Button {
                Task { await saveToHistory() }
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        SpinningView().scaleEffect(0.4).frame(width: 20, height: 20)
                    } else {
                        Image(systemName: didSave ? "checkmark" : "square.and.arrow.down")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(didSave ? "SAVED" : "SAVE TO HISTORY")
                        .font(.inter(14, weight: .black))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isSaving || didSave)
            .padding(.horizontal, 20)

            // Close
            Button {
                onClose()
            } label: {
                Text("DONE")
                    .font(.inter(14, weight: .bold))
                    .foregroundStyle(.gravel)
            }
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = processedVideoURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Process Video

    private func processVideo() {
        guard let videoURL, let gpxRoute else { return }
        withAnimation { step = .processing }

        Task {
            let result = GPXTelemetryCalculator.calculate(route: gpxRoute, videoDuration: videoDuration)

            let compositorSnapshots = result.snapshots.map { snap in
                OverlayCompositor.TelemetrySnapshot(
                    timestamp: snap.timestamp,
                    speed: snap.speed,
                    maxSpeed: snap.maxSpeed,
                    avgSpeed: snap.avgSpeed,
                    distance: snap.distance,
                    elapsed: snap.timestamp
                )
            }

            if let outputURL = await OverlayCompositor.composeOverlay(
                videoURL: videoURL,
                telemetrySnapshots: compositorSnapshots
            ) {
                processedVideoURL = outputURL
                _ = await VideoSaveHelper.saveToPhotos(videoURL: outputURL)
            }

            withAnimation { step = .done }
        }
    }

    // MARK: - Save to History

    private func saveToHistory() async {
        guard let userId = SupabaseManager.shared.currentUserId else { return }
        isSaving = true

        let sessionId = UUID()
        let result = gpxRoute.map { GPXTelemetryCalculator.calculate(route: $0, videoDuration: videoDuration) }

        let session = Session(
            id: sessionId,
            userId: userId,
            name: routeName,
            date: Date(),
            distance: result?.totalDistance ?? 0,
            duration: videoDuration,
            hasVideo: processedVideoURL != nil
        )

        let telemetry = DBTelemetryData(
            sessionId: sessionId,
            maxSpeed: result?.maxSpeed ?? 0,
            avgSpeed: result?.avgSpeed ?? 0,
            distance: result?.totalDistance ?? 0,
            snapshots: result?.snapshots
        )

        do {
            try await SessionService.shared.createSession(session)
            try await TelemetryService.shared.saveTelemetry(telemetry)
            HapticManager.notification(.success)
            didSave = true
        } catch {
            print("[GPX] Failed to save: \(error)")
        }

        isSaving = false
    }

    // MARK: - Helpers

    private func loadVideo(from item: PhotosPickerItem) async throws -> URL? {
        guard let data = try await item.loadTransferable(type: Data.self) else { return nil }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("gpx_video_\(UUID().uuidString).mov")
        try data.write(to: tempURL)
        return tempURL
    }

    private var regionForRoute: MKCoordinateRegion {
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return MKCoordinateRegion() }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.005)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    private var formattedDistance: String {
        guard coordinates.count >= 2 else { return "0 km" }
        var total: Double = 0
        for i in 1..<coordinates.count {
            let from = CLLocation(latitude: coordinates[i - 1].latitude, longitude: coordinates[i - 1].longitude)
            let to = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            total += to.distance(from: from)
        }
        return String(format: "%.1f km", total / 1000)
    }

    private func statLabel(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.inter(10, weight: .bold))
                .foregroundStyle(.gravel)
            Text(value)
                .font(.inter(18, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    GPXPreviewView(
        routeName: "Sierra Nevada Trail",
        coordinates: [
            CLLocationCoordinate2D(latitude: 37.088, longitude: -3.388),
            CLLocationCoordinate2D(latitude: 37.090, longitude: -3.385),
            CLLocationCoordinate2D(latitude: 37.093, longitude: -3.380),
            CLLocationCoordinate2D(latitude: 37.095, longitude: -3.375),
        ],
        gpxRoute: nil,
        onClose: {}
    )
}
