import SwiftUI

struct CommentRowView: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.mist)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(String(comment.authorName.prefix(1)).uppercased())
                        .font(.inter(12, weight: .bold))
                        .foregroundStyle(Color.gravel)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.authorName)
                        .font(.inter(13, weight: .semibold))
                        .foregroundStyle(Color.coal)
                    Text(comment.formattedDate)
                        .font(.inter(11, weight: .regular))
                        .foregroundStyle(Color.gravel)
                }

                Text(comment.content)
                    .font(.inter(13, weight: .regular))
                    .foregroundStyle(Color.asphalt)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(Comment.mockData) { comment in
            CommentRowView(comment: comment)
        }
    }
}
