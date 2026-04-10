import SwiftUI
import MapKit
import Supabase

struct TripSummaryView: View {
    let maxSpeed: String
    let avgSpeed: String
    let distance: String
    let time: String
    let durationSeconds: TimeInterval
    let distanceKm: Double
    let maxSpeedValue: Double
    let avgSpeedValue: Double
    let routeCoordinates: [CLLocationCoordinate2D]
    var telemetrySnapshots: [TelemetrySnapshot] = []
    var videoLocalIdentifier: String? = nil
    var videoThumbnail: UIImage? = nil

    var onClose: (() -> Void)?

    @State private var tripName = ""
    @State private var isSaving = false
    @State private var showShareSheet = false
    @State private var showSharePicker = false
    @State private var showReelBuilder = false
    @State private var selectedTemplate: ShareTemplate = .mapCard
    @State private var shareImage: UIImage?
    @State private var mapSnapshot: UIImage?
    @State private var videoURL: URL?
    @State private var locationName = ""
    @State private var isLoadingMap = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .opacity(0)

                Spacer()

                Text("KINETIC")
                    .font(.inter(16, weight: .black))
                    .foregroundStyle(.stravaOrange)

                Spacer()

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
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.black)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Route map
                    ZStack(alignment: .bottomLeading) {
                        routeMapView
                            .frame(height: 260)

                        // Trip info overlay
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.7)],
                            startPoint: .center,
                            endPoint: .bottom
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 10))
                                    Text(formattedDate)
                                        .font(.inter(11, weight: .medium))
                                }
                                if !locationName.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin")
                                            .font(.system(size: 10))
                                        Text(locationName.uppercased())
                                            .font(.inter(11, weight: .medium))
                                    }
                                }
                            }
                            .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Main stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 1),
                        GridItem(.flexible(), spacing: 1)
                    ], spacing: 1) {
                        statCard(label: LanguageManager.shared.localizedString("trip.maxSpeed"), value: maxSpeed, unit: "KM/H")
                        statCard(label: LanguageManager.shared.localizedString("trip.distance"), value: distance, unit: "KM")
                        statCard(label: LanguageManager.shared.localizedString("trip.avgSpeed"), value: avgSpeed, unit: "KM/H")
                        statCard(label: LanguageManager.shared.localizedString("trip.time"), value: time, unit: "")
                    }
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Share button
                    Button {
                        showSharePicker = true
                        HapticManager.impact(.medium)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                            Text(localized: "trip.share")
                                .font(.inter(15, weight: .black))
                                .tracking(1)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.stravaOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)

                    // Create Reel button (only if we have video)
                    if videoLocalIdentifier != nil, let videoURL {
                        Button {
                            showReelBuilder = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "film")
                                    .font(.system(size: 16, weight: .bold))
                                Text(LanguageManager.shared.localizedString("reel.createReel"))
                                    .font(.inter(15, weight: .black))
                                    .tracking(1)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.stravaOrange.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }

                    // Trip name input
                    TextField("", text: $tripName, prompt: Text(LanguageManager.shared.localizedString("trip.namePlaceholder")).foregroundStyle(.gravel))
                        .font(.inter(14, weight: .regular))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    // Save button
                    Button {
                        guard !isSaving else { return }
                        isSaving = true
                        Task {
                            await saveToHistory()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            Text(localized: "trip.save")
                                .font(.inter(14, weight: .black))
                                .tracking(1)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .disabled(isSaving)
                    .opacity(isSaving ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(.black)
        .task {
            async let snapshotTask: Void = {
                mapSnapshot = await MapSnapshotHelper.generateSnapshot(coordinates: routeCoordinates)
            }()
            async let geocodeTask: Void = reverseGeocodeLocation()
            async let videoTask: Void = {
                if let localId = videoLocalIdentifier {
                    videoURL = await VideoSaveHelper.fetchVideoURL(localIdentifier: localId)
                }
            }()
            _ = await (snapshotTask, geocodeTask, videoTask)
            withAnimation { isLoadingMap = false }
        }
        .sheet(isPresented: $showSharePicker) {
            ShareTemplatePickerView(
                shareData: currentShareData,
                onShare: { template in
                    showSharePicker = false
                    shareImage = generateShareImage(data: currentShareData, template: template)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showShareSheet = true
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
        .fullScreenCover(isPresented: $showReelBuilder) {
            if let videoURL {
                ReelBuilderView(
                    videoURL: videoURL,
                    tripName: tripName.isEmpty ? "KINETIC DRIVE" : tripName,
                    maxSpeed: maxSpeed,
                    avgSpeed: avgSpeed,
                    distance: distance,
                    time: time,
                    mapSnapshot: mapSnapshot,
                    routePoints: MapSnapshotHelper.normalizeCoordinates(routeCoordinates)
                )
            }
        }
    }

    // MARK: - Route Map

    @ViewBuilder
    private var routeMapView: some View {
        if isLoadingMap {
            Rectangle()
                .fill(Color(hex: 0x2A2A2E))
                .overlay {
                    SpinningView()
                }
        } else if routeCoordinates.count >= 2 {
            ZStack(alignment: .bottomLeading) {
                Map(initialPosition: .region(regionForRoute)) {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(Color.stravaOrange, lineWidth: 4)
                }
                .mapStyle(KineticMapStyle.route)
                .mapControlVisibility(.hidden)
                .allowsHitTesting(false)

                // Cover Apple legal text in bottom-left
                LinearGradient(
                    colors: [.black.opacity(0.8), .clear],
                    startPoint: .bottomLeading,
                    endPoint: .center
                )
                .frame(width: 120, height: 40)
            }
        } else {
            Rectangle()
                .fill(Color(hex: 0x2A2A2E))
                .overlay {
                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundStyle(.gravel.opacity(0.3))
                }
        }
    }

    private var regionForRoute: MKCoordinateRegion {
        let lats = routeCoordinates.map(\.latitude)
        let lons = routeCoordinates.map(\.longitude)
        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let padding = 1.5 // 50% extra space around route
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * padding, 0.005),
            longitudeDelta: max((maxLon - minLon) * padding, 0.005)
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: - Reverse Geocode

    private func reverseGeocodeLocation() async {
        guard let coord = routeCoordinates.first else { return }
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality ?? ""
                let country = placemark.country ?? ""
                if !city.isEmpty && !country.isEmpty {
                    locationName = "\(city), \(country)"
                } else {
                    locationName = country.isEmpty ? city : country
                }
            }
        } catch {
            debugPrint("[TripSummary] Geocode failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Share Data

    private var currentShareData: ShareData {
        ShareData(
            tripName: tripName.isEmpty ? "KINETIC DRIVE" : tripName,
            date: formattedDate,
            maxSpeed: maxSpeed,
            avgSpeed: avgSpeed,
            distance: distance,
            time: time,
            mapSnapshot: mapSnapshot,
            routePoints: MapSnapshotHelper.normalizeCoordinates(routeCoordinates)
        )
    }

    // MARK: - Formatted Date

    private var formattedDate: String {
        Date().formatted(.dateTime.month(.abbreviated).day().year()).uppercased()
    }

    // MARK: - Save

    private func saveToHistory() async {
        guard let userId = SupabaseManager.shared.currentUserId else {
            print("[TripSummary] No authenticated user, skipping save")
            dismiss()
            return
        }

        let sessionId = UUID()
        let sessionName = tripName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Unnamed Trip"
            : tripName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Upload thumbnail to Supabase if we have one
        var thumbnailUrl: String?
        if let thumbnail = videoThumbnail,
           let jpegData = thumbnail.jpegData(compressionQuality: 0.7) {
            do {
                let path = "\(userId.uuidString)/\(sessionId.uuidString)/thumbnail.jpg"
                try await SupabaseManager.shared.client?
                    .storage
                    .from("sessions")
                    .upload(path, data: jpegData, options: .init(contentType: "image/jpeg", upsert: true))
                thumbnailUrl = try SupabaseManager.shared.client?
                    .storage
                    .from("sessions")
                    .getPublicURL(path: path)
                    .absoluteString
            } catch {
                print("[TripSummary] Failed to upload thumbnail: \(error)")
            }
        }

        let hasVideo = videoLocalIdentifier != nil

        let session = Session(
            id: sessionId,
            userId: userId,
            name: sessionName,
            date: Date(),
            distance: distanceKm,
            duration: durationSeconds,
            hasVideo: hasVideo,
            thumbnailUrl: thumbnailUrl,
            videoUrl: videoLocalIdentifier, // Store Photos local identifier
            locationName: locationName.isEmpty ? nil : locationName
        )

        let telemetry = DBTelemetryData(
            sessionId: sessionId,
            maxSpeed: maxSpeedValue,
            avgSpeed: avgSpeedValue,
            distance: distanceKm,
            snapshots: telemetrySnapshots.isEmpty ? nil : telemetrySnapshots
        )

        do {
            try await SessionService.shared.createSession(session)
            try await TelemetryService.shared.saveTelemetry(telemetry)
            HapticManager.notification(.success)
        } catch {
            print("[TripSummary] Failed to save session: \(error)")
        }

        dismiss()
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
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
    TripSummaryView(
        maxSpeed: "184",
        avgSpeed: "84",
        distance: "14.2",
        time: "00:12:45",
        durationSeconds: 765,
        distanceKm: 14.2,
        maxSpeedValue: 184,
        avgSpeedValue: 84,
        routeCoordinates: [
            CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
            CLLocationCoordinate2D(latitude: 41.3900, longitude: 2.1800),
            CLLocationCoordinate2D(latitude: 41.3950, longitude: 2.1750),
            CLLocationCoordinate2D(latitude: 41.3920, longitude: 2.1680),
            CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
        ]
    )
}
