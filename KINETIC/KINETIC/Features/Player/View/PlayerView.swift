import SwiftUI
import AVKit

struct PlayerView: View {
    let sessionId: UUID
    @State private var viewModel: PlayerViewModel
    @State private var avPlayer: AVPlayer?
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

                Button {} label: {
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
                    // Video player area with overlays
                    ZStack(alignment: .bottom) {
                        // Video player or placeholder
                        if let avPlayer {
                            VideoPlayer(player: avPlayer)
                                .aspectRatio(16 / 10, contentMode: .fit)
                        } else {
                            Rectangle()
                                .fill(Color.asphalt)
                                .aspectRatio(16 / 10, contentMode: .fit)
                                .overlay {
                                    if viewModel.session?.hasVideo == true {
                                        SpinningView()
                                            .scaleEffect(0.6)
                                    } else {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.white.opacity(0.3))
                                    }
                                }
                        }

                        // Telemetry overlays — dynamic if snapshots available
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 8) {
                                // Speed
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
                                            Text("KM/H")
                                                .font(.inter(11, weight: .bold))
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                    }
                                }

                                // Distance
                                telemetryOverlay {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(localized: "player.distance")
                                            .font(.inter(8, weight: .bold))
                                            .tracking(1)
                                            .foregroundStyle(.white.opacity(0.7))
                                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                                            Text(viewModel.hasDynamicData ? viewModel.liveDistance : viewModel.distanceValue)
                                                .font(.inter(28, weight: .black))
                                                .foregroundStyle(.white)
                                                .contentTransition(.numericText())
                                            Text("KM")
                                                .font(.inter(12, weight: .bold))
                                                .foregroundStyle(.white.opacity(0.5))
                                        }
                                    }
                                }
                            }

                            Spacer()

                            // Session time
                            telemetryOverlay {
                                VStack(spacing: 2) {
                                    Text(localized: "player.sessionTime")
                                        .font(.inter(8, weight: .bold))
                                        .tracking(1)
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text(viewModel.hasDynamicData ? viewModel.liveTime : viewModel.formattedDuration)
                                        .font(.inter(22, weight: .black))
                                        .foregroundStyle(.white)
                                        .contentTransition(.numericText())
                                }
                            }
                        }
                        .padding(12)

                        // Progress bar — dynamic
                        VStack(spacing: 0) {
                            Spacer()
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 4)
                                    Rectangle()
                                        .fill(.stravaOrange)
                                        .frame(width: geo.size.width * viewModel.playbackProgress, height: 4)
                                    Circle()
                                        .fill(.stravaOrange)
                                        .frame(width: 12, height: 12)
                                        .offset(x: max(0, geo.size.width * viewModel.playbackProgress - 6))
                                }
                            }
                            .frame(height: 12)
                        }
                    }

                    // Session info - dark section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.sessionName)
                            .font(.inter(24, weight: .extraBold))
                            .foregroundStyle(.white)

                        Text(viewModel.sessionDateText)
                            .font(.inter(14, weight: .regular))
                            .foregroundStyle(.gravel)

                        // Telemetry grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            TelemetryCard(title: LanguageManager.shared.localizedString("player.distance"), value: viewModel.distanceValue, unit: "KM")
                            TelemetryCard(title: LanguageManager.shared.localizedString("player.elevation"), value: viewModel.elevationValue, unit: "M")
                            TelemetryCard(title: LanguageManager.shared.localizedString("player.maxAlt"), value: viewModel.maxAltitudeValue, unit: "M")
                            TelemetryCard(title: LanguageManager.shared.localizedString("player.consumption"), value: viewModel.fuelValue, unit: "L")
                        }
                        .padding(.top, 8)
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
        }
        .onDisappear {
            if let avPlayer {
                viewModel.removeObserver(from: avPlayer)
            }
        }
        .alert("Delete Session", isPresented: $viewModel.showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteSession()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this session? This action cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
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

#Preview {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                PlayerView(session: Session.mockData[0])
            }
    }
}
