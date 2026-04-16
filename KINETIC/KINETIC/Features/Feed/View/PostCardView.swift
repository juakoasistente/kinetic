import SwiftUI

struct PostCardView: View {
    let post: Post
    var onLike: () -> Void = {}
    var onComment: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Author Header
            authorHeader

            // MARK: - Media
            if let media = post.media, !media.isEmpty {
                MediaCarouselView(media: media.sorted { $0.sortOrder < $1.sortOrder })
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

#Preview {
    PostCardView(post: Post.mockData[0])
}
