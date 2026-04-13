import SwiftUI

struct PostDetailView: View {
    let post: Post
    @State private var viewModel: PostDetailViewModel

    init(post: Post) {
        self.post = post
        self._viewModel = State(initialValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Post Card
                PostCardView(
                    post: viewModel.post,
                    onLike: { Task { await viewModel.toggleLike() } },
                    onComment: { viewModel.isCommentFieldFocused = true },
                    onShare: {},
                    onBookmark: { Task { await viewModel.toggleBookmark() } }
                )

                // Comments Section
                commentsSection
            }
        }
        .background(Color.fog)
        .dismissKeyboardOnTap()
        .safeAreaInset(edge: .bottom) {
            commentInputBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadComments()
        }
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LanguageManager.shared.localizedString("feed.comments"))
                .font(.inter(14, weight: .bold))
                .foregroundStyle(Color.coal)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            if viewModel.comments.isEmpty && !viewModel.isLoadingComments {
                Text(LanguageManager.shared.localizedString("feed.noComments"))
                    .font(.inter(13, weight: .regular))
                    .foregroundStyle(Color.gravel)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
            } else {
                ForEach(viewModel.comments) { comment in
                    CommentRowView(comment: comment)
                }
            }
        }
        .background(Color.white)
    }

    // MARK: - Comment Input

    private var commentInputBar: some View {
        HStack(spacing: 12) {
            TextField(
                LanguageManager.shared.localizedString("feed.addComment"),
                text: $viewModel.newCommentText
            )
            .font(.inter(14, weight: .regular))
            .textFieldStyle(.plain)

            Button {
                Task { await viewModel.submitComment() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        viewModel.newCommentText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.silver : Color.stravaOrange
                    )
            }
            .disabled(viewModel.newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

#Preview {
    NavigationStack {
        PostDetailView(post: Post.mockData[0])
    }
}
