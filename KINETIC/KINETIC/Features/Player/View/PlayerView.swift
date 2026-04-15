import SwiftUI
import AVKit
import MapKit

struct PlayerView: View {
    let sessionId: UUID
    @State private var viewModel: PlayerViewModel
    @State private var avPlayer: AVPlayer?
    @State private var showRouteMap = false
    @State private var showSharePicker = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var mapSnapshot: UIImage?
    @Environment(\.dismiss) private var dismiss

    init(session: Session) {
        self.sessionId = session.id
        self._viewModel = State(initialValue: PlayerViewModel(sessionId: session.id, session: session))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image("back")
                            .renderingMode(.template)
                            .foregroundStyle(.stravaOrange)
                        Text(localized: "player.back")
                            .font(.inter(16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                Spacer()

                Button {
                    showSharePicker = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundStyle(.gravel)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.black)

            ScrollView {
                VStack(spacing: 0) {
                    // Video or Route Map
                    if viewModel.session?.hasVideo == true {
                        videoPlayerSection
                    } else {
                        routeMapSection
                    }

                    // Session info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.sessionName)
                            .font(.inter(24, weight: .extraBold))
                            .foregroundStyle(.white)

                        if let location = viewModel.session?.locationName, !location.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 10))
                                Text(location.uppercased())
                                    .font(.inter(11, weight: .medium))
                            }
                            .foregroundStyle(.gravel)
                        }

                        Text(viewModel.sessionDateText)
                            .font(.inter(14, weight: .regular))
                            .foregroundStyle(.gravel)

                        // Telemetry grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            TelemetryCard(title: LanguageManager.shared.localizedString("player.speed"), value: viewModel.speedValue, unit: "KM/H")
                            TelemetryCard(title: LanguageManager.shared.localizedString("player.distance"), value: viewModel.distanceValue, unit: "KM")
                            TelemetryCard(title: LanguageManager.shared.localizedString("player.elevation"), value: viewModel.elevationValue, unit: "M")
                            TelemetryCard(title: LanguageManager.shared.localizedString("player.sessionTime"), value: viewModel.formattedDuration, unit: "")
                        }
                        .padding(.top, 8)

                        // View Route button (only for video sessions with telemetry)
                        if viewModel.session?.hasVideo == true, !viewModel.snapshots.isEmpty {
                            Button {
                                showRouteMap = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(LanguageManager.shared.localizedString("player.route"))
                                        .font(.inter(13, weight: .bold))
                                        .tracking(0.5)
                                }
                                .foregroundStyle(.stravaOrange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.stravaOrange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.top, 12)
                        }
                    }
                    .padding(24)
                }
            }

            // Bottom action
            Button {
                viewModel.showDeleteAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                    Text(LanguageManager.shared.localizedString("player.delete"))
                        .font(.inter(14, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundStyle(.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.danger.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(.black)
        .navigationBarHidden(true)
        .toolbarVisibility(.hidden, for: .tabBar)
        .swipeBack { dismiss() }
        .task {
            await viewModel.loadSession()
            // Load video from Photos if session has video
            if let session = viewModel.session,
               session.hasVideo,
               let localId = session.videoUrl {
                if let videoURL = await VideoSaveHelper.fetchVideoURL(localIdentifier: localId) {
                    let player = AVPlayer(url: videoURL)
                    avPlayer = player
                    viewModel.observePlayer(player)
                }
            }
            // Generate map snapshot for sharing
            let coords = viewModel.snapshots.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            if coords.count >= 2 {
                mapSnapshot = await MapSnapshotHelper.generateSnapshot(coordinates: coords)
            }
        }
        .onDisappear {
            if let avPlayer {
                viewModel.removeObserver(from: avPlayer)
            }
        }
        .alert(LanguageManager.shared.localizedString("player.deleteTitle"), isPresented: $viewModel.showDeleteAlert) {
            Button(LanguageManager.shared.localizedString("alert.cancel"), role: .cancel) {}
            Button(LanguageManager.shared.localizedString("alert.delete"), role: .destructive) {
                Task {
                    await viewModel.deleteSession()
                    dismiss()
                }
            }
        } message: {
            Text(LanguageManager.shared.localizedString("player.deleteMessage"))
        }
        .alert(LanguageManager.shared.localizedString("alert.error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(LanguageManager.shared.localizedString("alert.ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $showRouteMap) {
            RouteMapModal(snapshots: viewModel.snapshots, sessionName: viewModel.sessionName)
        }
        .sheet(isPresented: $showSharePicker) {
            ShareTemplatePickerView(shareData: currentShareData) { template in
                showSharePicker = false
                shareImage = generateShareImage(data: currentShareData, template: template)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showShareSheet = true
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    // MARK: - Share Data

    private var currentShareData: ShareData {
        let coords = viewModel.snapshots.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        return ShareData(
            tripName: viewModel.sessionName,
            date: viewModel.sessionDateText.uppercased(),
            maxSpeed: viewModel.speedValue,
            avgSpeed: viewModel.dbTelemetry.map { String(format: "%.0f", $0.avgSpeed) } ?? "--",
            distance: viewModel.distanceValue,
            time: viewModel.formattedDuration,
            mapSnapshot: mapSnapshot,
            routePoints: MapSnapshotHelper.normalizeCoordinates(coords)
        )
    }

    // MARK: - Video Player Section

    private var videoPlayerSection: some View {
        ZStack(alignment: .bottom) {
            if let avPlayer {
                VideoPlayer(player: avPlayer)
                    .aspectRatio(16 / 10, contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.asphalt)
                    .aspectRatio(16 / 10, contentMode: .fit)
                    .overlay { SpinningView().scaleEffect(0.6) }
            }

            // Live telemetry overlays
            HStack(alignment: .bottom) {
                telemetryOverlay {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localized: "player.speed")
                            .font(.inter(8, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.7))
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(viewModel.hasDynamicData ? viewModel.liveSpeed : viewModel.speedValue)
                                .font(.inter(32, weight: .black))
                                .foregroundStyle(.stravaOrange)
                                .contentTransition(.numericText())
                            Text(LanguageManager.shared.localizedString("overlay.kmh"))
                                .font(.inter(11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }

                Spacer()

                telemetryOverlay {
                    VStack(spacing: 2) {
                        Text(localized: "player.sessionTime")
                            .font(.inter(8, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(viewModel.hasDynamicData ? viewModel.liveTime : viewModel.formattedDuration)
                            .font(.inter(18, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .contentTransition(.numericText())
                    }
                }
            }
            .padding(12)

            // Progress bar
            VStack(spacing: 0) {
                Spacer()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.white.opacity(0.2)).frame(height: 4)
                        Rectangle().fill(.stravaOrange).frame(width: geo.size.width * viewModel.playbackProgress, height: 4)
                        Circle().fill(.stravaOrange).frame(width: 12, height: 12)
                            .offset(x: max(0, geo.size.width * viewModel.playbackProgress - 6))
                    }
                }
                .frame(height: 12)
            }
        }
    }

    // MARK: - Route Map Section (data-only sessions)

    private var routeMapSection: some View {
        ZStack(alignment: .bottomLeading) {
            if viewModel.isLoading {
                Rectangle()
                    .fill(Color(hex: 0x2A2A2E))
                    .frame(height: 260)
                    .overlay { SpinningView().scaleEffect(0.6) }
            } else if !viewModel.snapshots.isEmpty {
                let coords = viewModel.snapshots.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                Map(initialPosition: .region(regionFor(coords))) {
                    MapPolyline(coordinates: coords)
                        .stroke(KineticMapStyle.routeColor, lineWidth: KineticMapStyle.routeLineWidth)
                }
                .mapStyle(KineticMapStyle.route)
                .mapControlVisibility(.hidden)
                .allowsHitTesting(false)
                .frame(height: 260)
            } else {
                Rectangle()
                    .fill(Color(hex: 0x2A2A2E))
                    .frame(height: 260)
                    .overlay {
                        Image(systemName: "map")
                            .font(.system(size: 40))
                            .foregroundStyle(.gravel.opacity(0.3))
                    }
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 260)
        }
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    private func regionFor(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            return MKCoordinateRegion()
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.005)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: - Helpers

    private func telemetryOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(10)
            .background(.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.inter(10, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Route Map Modal

struct RouteMapModal: View {
    let snapshots: [TelemetrySnapshot]
    let sessionName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(LanguageManager.shared.localizedString("player.route"))
                    .font(.inter(14, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.white)

                Spacer()

                // Balance spacer
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.black)

            // Map
            if !snapshots.isEmpty {
                let coords = snapshots.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                Map(initialPosition: .region(regionFor(coords))) {
                    MapPolyline(coordinates: coords)
                        .stroke(KineticMapStyle.routeColor, lineWidth: KineticMapStyle.routeLineWidth)
                }
                .mapStyle(KineticMapStyle.route)
                .ignoresSafeArea(edges: .bottom)
            } else {
                Color(hex: 0x2A2A2E)
                    .overlay {
                        Image(systemName: "map")
                            .font(.system(size: 40))
                            .foregroundStyle(.gravel.opacity(0.3))
                    }
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(.black)
    }

    private func regionFor(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            return MKCoordinateRegion()
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.005)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                PlayerView(session: Session.mockData[0])
            }
    }
}
