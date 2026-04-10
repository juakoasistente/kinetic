import SwiftUI
import AVKit

struct ReelBuilderView: View {
    let videoURL: URL
    let tripName: String
    let maxSpeed: String
    let avgSpeed: String
    let distance: String
    let time: String
    let mapSnapshot: UIImage?
    let routePoints: [CGPoint]

    @State private var clips: [ClipSelection] = []
    @State private var videoDuration: TimeInterval = 0
    @State private var isGenerating = false
    @State private var generatedReelURL: URL?
    @State private var showShareSheet = false
    @State private var showPreview = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("CREATE REEL")
                    .font(.inter(14, weight: .black))
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

            ScrollView {
                VStack(spacing: 24) {
                    // Trimmer
                    VideoTrimmerView(
                        videoURL: videoURL,
                        videoDuration: videoDuration,
                        clips: $clips
                    )
                    .padding(.horizontal, 20)

                    // Reel preview info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REEL STRUCTURE")
                            .font(.inter(11, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.gravel)

                        reelStructureRow(icon: "play.rectangle.fill", label: "Intro", detail: "2s — KINETIC logo + trip name")
                        reelStructureRow(icon: "film", label: "Highlights", detail: "\(clips.count) clip\(clips.count == 1 ? "" : "s") selected")
                        reelStructureRow(icon: "chart.bar.fill", label: "Summary", detail: "5s — Map + stats")
                    }
                    .padding(.horizontal, 20)

                    let totalDuration = 7 + clips.reduce(0) { $0 + $1.duration }
                    Text("Estimated reel: \(formatTime(totalDuration))")
                        .font(.inter(13, weight: .medium))
                        .foregroundStyle(.gravel)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            // Bottom button
            VStack(spacing: 12) {
                Button {
                    Task { await generateReel() }
                } label: {
                    HStack(spacing: 10) {
                        if isGenerating {
                            SpinningView()
                                .scaleEffect(0.5)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 16, weight: .bold))
                        }
                        Text(isGenerating ? "GENERATING..." : "CREATE REEL")
                            .font(.inter(15, weight: .black))
                            .tracking(1)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(clips.isEmpty || isGenerating ? Color.gravel : Color.stravaOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(clips.isEmpty || isGenerating)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
        .background(.black)
        .task {
            await loadVideoDuration()
            // Auto-add a default clip if empty
            if clips.isEmpty && videoDuration > 3 {
                let end = min(10, videoDuration)
                clips.append(ClipSelection(startTime: 0, endTime: end))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = generatedReelURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Reel Structure Row

    private func reelStructureRow(icon: String, label: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.stravaOrange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.inter(13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.inter(12, weight: .regular))
                    .foregroundStyle(.gravel)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Generate

    private func generateReel() async {
        isGenerating = true

        let config = ReelCompositor.ReelConfig(
            videoURL: videoURL,
            clips: clips,
            tripName: tripName,
            maxSpeed: maxSpeed,
            avgSpeed: avgSpeed,
            distance: distance,
            time: time,
            mapSnapshot: mapSnapshot,
            routePoints: routePoints
        )

        generatedReelURL = await ReelCompositor.generateReel(config: config)

        isGenerating = false

        if generatedReelURL != nil {
            // Save reel to Photos too
            if let url = generatedReelURL {
                _ = await VideoSaveHelper.saveToPhotos(videoURL: url)
            }
            HapticManager.notification(.success)
            showShareSheet = true
        } else {
            HapticManager.notification(.error)
        }
    }

    // MARK: - Helpers

    private func loadVideoDuration() async {
        let asset = AVURLAsset(url: videoURL)
        if let duration = try? await asset.load(.duration) {
            videoDuration = duration.seconds
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    ReelBuilderView(
        videoURL: URL(fileURLWithPath: "/dev/null"),
        tripName: "Sierra Route",
        maxSpeed: "142",
        avgSpeed: "84",
        distance: "48.2",
        time: "48:47",
        mapSnapshot: nil,
        routePoints: []
    )
}
