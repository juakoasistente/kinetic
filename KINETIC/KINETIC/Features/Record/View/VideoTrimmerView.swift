import SwiftUI
import AVKit
import AVFoundation

// MARK: - Clip Selection

struct ClipSelection: Identifiable, Equatable {
    let id = UUID()
    var startTime: TimeInterval
    var endTime: TimeInterval

    var duration: TimeInterval { endTime - startTime }
}

// MARK: - Video Trimmer View

struct VideoTrimmerView: View {
    let videoURL: URL
    let videoDuration: TimeInterval
    @Binding var clips: [ClipSelection]
    var maxClips: Int = 3
    var minClipDuration: TimeInterval = 3
    var maxClipDuration: TimeInterval = 20

    @State private var player: AVPlayer?
    @State private var currentTime: TimeInterval = 0
    @State private var thumbnails: [UIImage] = []
    @State private var editingClipIndex: Int? = nil
    @State private var isGeneratingThumbnails = false

    var body: some View {
        VStack(spacing: 16) {
            // Video preview
            if let player {
                VideoPlayer(player: player)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Rectangle()
                    .fill(Color(hex: 0x2A2A2E))
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay { SpinningView() }
            }

            // Timeline with thumbnails
            VStack(alignment: .leading, spacing: 8) {
                Text("SELECT HIGHLIGHTS")
                    .font(.inter(11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.gravel)

                ZStack(alignment: .leading) {
                    // Thumbnail strip
                    thumbnailStrip
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Clip overlays
                    ForEach(clips.indices, id: \.self) { index in
                        clipOverlay(index: index)
                    }

                    // Playhead
                    if videoDuration > 0 {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 56)
                            .offset(x: CGFloat(currentTime / videoDuration) * timelineWidth)
                    }
                }
                .frame(height: 56)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let time = TimeInterval(value.location.x / timelineWidth) * videoDuration
                            let clampedTime = max(0, min(time, videoDuration))
                            seekTo(clampedTime)
                        }
                )

                // Clip list
                HStack(spacing: 8) {
                    ForEach(clips.indices, id: \.self) { index in
                        clipBadge(index: index)
                    }

                    if clips.count < maxClips {
                        Button {
                            addClip()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Add clip")
                                    .font(.inter(12, weight: .semibold))
                            }
                            .foregroundStyle(.stravaOrange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.stravaOrange.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }

                // Duration info
                let totalClipDuration = clips.reduce(0) { $0 + $1.duration }
                Text("Total: \(formatTime(totalClipDuration)) of highlights selected")
                    .font(.inter(12, weight: .medium))
                    .foregroundStyle(.gravel)
            }
        }
        .task {
            await setupPlayer()
            await generateThumbnails()
        }
    }

    // MARK: - Timeline Width

    private var timelineWidth: CGFloat {
        UIScreen.main.bounds.width - 40 // padding
    }

    // MARK: - Thumbnail Strip

    private var thumbnailStrip: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                if thumbnails.isEmpty {
                    Rectangle()
                        .fill(Color(hex: 0x3A3A3E))
                } else {
                    ForEach(thumbnails.indices, id: \.self) { index in
                        Image(uiImage: thumbnails[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width / CGFloat(max(thumbnails.count, 1)), height: geo.size.height)
                            .clipped()
                    }
                }
            }
        }
    }

    // MARK: - Clip Overlay

    private func clipOverlay(index: Int) -> some View {
        let clip = clips[index]
        let startX = CGFloat(clip.startTime / videoDuration) * timelineWidth
        let width = CGFloat(clip.duration / videoDuration) * timelineWidth

        return Rectangle()
            .fill(Color.stravaOrange.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.stravaOrange, lineWidth: 2)
            )
            .frame(width: max(width, 10), height: 48)
            .offset(x: startX)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let delta = TimeInterval(value.translation.width / timelineWidth) * videoDuration
                        var newStart = clips[index].startTime + delta
                        let duration = clips[index].duration
                        newStart = max(0, min(newStart, videoDuration - duration))
                        clips[index].startTime = newStart
                        clips[index].endTime = newStart + duration
                        seekTo(newStart)
                    }
            )
    }

    // MARK: - Clip Badge

    private func clipBadge(index: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.stravaOrange)
                .frame(width: 8, height: 8)
            Text("Clip \(index + 1): \(formatTime(clips[index].duration))")
                .font(.inter(12, weight: .medium))
                .foregroundStyle(.white)

            Button {
                clips.remove(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.gravel)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - Actions

    private func addClip() {
        let start = min(currentTime, videoDuration - minClipDuration)
        let end = min(start + 10, videoDuration) // Default 10 sec clip
        clips.append(ClipSelection(startTime: max(0, start), endTime: end))
    }

    private func seekTo(_ time: TimeInterval) {
        currentTime = time
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // MARK: - Setup

    private func setupPlayer() async {
        player = AVPlayer(url: videoURL)
    }

    private func generateThumbnails() async {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 120, height: 80)

        let count = 15
        var images: [UIImage] = []

        for i in 0..<count {
            let time = CMTime(seconds: videoDuration * Double(i) / Double(count), preferredTimescale: 600)
            do {
                let (cgImage, _) = try await generator.image(at: time)
                images.append(UIImage(cgImage: cgImage))
            } catch {
                continue
            }
        }

        thumbnails = images
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VideoTrimmerView(
            videoURL: URL(fileURLWithPath: "/dev/null"),
            videoDuration: 120,
            clips: .constant([
                ClipSelection(startTime: 10, endTime: 25),
                ClipSelection(startTime: 60, endTime: 72),
            ])
        )
        .padding(20)
    }
}
