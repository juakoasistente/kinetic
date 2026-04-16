import SwiftUI
import AVKit

struct MediaCarouselView: View {
    let media: [PostMedia]
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                    Group {
                        if item.mediaType == .video {
                            CarouselVideoView(media: item)
                        } else {
                            CarouselImageView(media: item)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 320)

            // Page dots (only when more than 1 item)
            if media.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<media.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.stravaOrange : Color.white.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Capsule().fill(Color.black.opacity(0.4)))
                .padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Carousel Image View

private struct CarouselImageView: View {
    let media: PostMedia

    var body: some View {
        AsyncImage(url: URL(string: media.mediaUrl)) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color.mist)
                .frame(height: 320)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.silver)
                }
        }
    }
}

// MARK: - Carousel Video View

private struct CarouselVideoView: View {
    let media: PostMedia
    @State private var isPlaying = false
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if isPlaying, let player {
                VideoPlayer(player: player)
                    .frame(height: 320)
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ZStack {
                    AsyncImage(url: URL(string: media.mediaUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 320)
                                .clipped()
                        default:
                            Rectangle()
                                .fill(Color.coal)
                                .frame(height: 320)
                                .overlay {
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(Color.gravel)
                                }
                        }
                    }

                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                                .offset(x: 2)
                        }
                }
                .onTapGesture {
                    if let url = URL(string: media.mediaUrl) {
                        player = AVPlayer(url: url)
                        isPlaying = true
                        player?.play()
                    }
                }
            }
        }
    }
}
