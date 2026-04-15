import SwiftUI
import AVKit

struct PostCardView: View {
    let post: Post
    var onLike: () -> Void = {}
    var onComment: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Author Header
            authorHeader

            // MARK: - Media
            if let media = post.media, let firstMedia = media.first {
                if firstMedia.mediaType == .video {
                    VideoMediaView(media: firstMedia)
                } else {
                    imageSection(firstMedia)
                }
            }

            // MARK: - Description
            if !post.description.isEmpty {
                Text(post.description)
                    .font(.inter(14, weight: .regular))
                    .foregroundStyle(Color.coal)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

            // MARK: - Interaction Bar
            interactionBar
                .padding(.top, 12)

            Divider()
                .padding(.top, 12)
        }
        .background(Color.white)
    }

    // MARK: - Author Header

    private var authorHeader: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarUrl = post.authorAvatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    avatarPlaceholder
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorName)
                    .font(.inter(14, weight: .semibold))
                    .foregroundStyle(Color.coal)
                Text(post.formattedDate)
                    .font(.inter(12, weight: .regular))
                    .foregroundStyle(Color.gravel)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.mist)
            .frame(width: 40, height: 40)
            .overlay {
                Text(String(post.authorName.prefix(1)).uppercased())
                    .font(.inter(16, weight: .bold))
                    .foregroundStyle(Color.gravel)
            }
    }

    // MARK: - Image Media

    private func imageSection(_ media: PostMedia) -> some View {
        AsyncImage(url: URL(string: media.mediaUrl)) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color.mist)
                .frame(height: 220)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.silver)
                }
        }
        .padding(.top, 8)
    }

    // MARK: - Interaction Bar

    private var interactionBar: some View {
        HStack(spacing: 24) {
            // Like
            Button(action: onLike) {
                HStack(spacing: 6) {
                    Image(systemName: (post.isLikedByMe ?? false) ? "heart.fill" : "heart")
                        .foregroundStyle((post.isLikedByMe ?? false) ? Color.stravaOrange : Color.gravel)
                    if let count = post.likesCount, count > 0 {
                        Text("\(count)")
                            .font(.inter(13, weight: .medium))
                            .foregroundStyle(Color.gravel)
                    }
                }
            }

            // Comment
            Button(action: onComment) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .foregroundStyle(Color.gravel)
                    if let count = post.commentsCount, count > 0 {
                        Text("\(count)")
                            .font(.inter(13, weight: .medium))
                            .foregroundStyle(Color.gravel)
                    }
                }
            }
        }
        .font(.system(size: 20))
        .padding(.horizontal, 16)
    }
}

// MARK: - Video Media View

private struct VideoMediaView: View {
    let media: PostMedia
    @State private var isPlaying = false
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if isPlaying, let player {
                VideoPlayer(player: player)
                    .frame(height: 280)
                    .onDisappear {
                        player.pause()
                    }
            } else {
                // Thumbnail / placeholder with play button
                ZStack {
                    AsyncImage(url: URL(string: media.mediaUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .clipped()
                        default:
                            Rectangle()
                                .fill(Color.coal)
                                .frame(height: 220)
                                .overlay {
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(Color.gravel)
                                }
                        }
                    }

                    // Play button overlay
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
        .padding(.top, 8)
    }
}

#Preview {
    PostCardView(post: Post.mockData[0])
}
