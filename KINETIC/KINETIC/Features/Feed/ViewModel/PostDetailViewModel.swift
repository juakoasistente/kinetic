import Foundation

@Observable
final class PostDetailViewModel {
    var post: Post
    var comments: [Comment] = []
    var newCommentText = ""
    var isLoadingComments = false
    var isCommentFieldFocused = false
    var errorMessage: String?

    init(post: Post) {
        self.post = post
    }

    func loadComments() async {
        isLoadingComments = true
        do {
            comments = try await SocialService.shared.fetchComments(postId: post.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingComments = false
    }

    func submitComment() async {
        let text = newCommentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        newCommentText = ""
        do {
            let comment = try await SocialService.shared.addComment(postId: post.id, content: text)
            comments.append(comment)
            post.commentsCount = (post.commentsCount ?? 0) + 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleLike() async {
        let isLiked = post.isLikedByMe ?? false
        post.isLikedByMe = !isLiked
        post.likesCount = (post.likesCount ?? 0) + (isLiked ? -1 : 1)
        do {
            if isLiked {
                try await SocialService.shared.unlikePost(postId: post.id)
            } else {
                try await SocialService.shared.likePost(postId: post.id)
            }
        } catch {
            post.isLikedByMe = isLiked
            post.likesCount = (post.likesCount ?? 0) + (isLiked ? 1 : -1)
        }
    }

    func toggleBookmark() async {
        let isBookmarked = post.isBookmarkedByMe ?? false
        post.isBookmarkedByMe = !isBookmarked
        do {
            if isBookmarked {
                try await SocialService.shared.unbookmarkPost(postId: post.id)
            } else {
                try await SocialService.shared.bookmarkPost(postId: post.id)
            }
        } catch {
            post.isBookmarkedByMe = isBookmarked
        }
    }
}
