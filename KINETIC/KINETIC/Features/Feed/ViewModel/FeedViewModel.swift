import Foundation

@Observable
final class FeedViewModel {
    var posts: [Post] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    private var offset = 0
    private let pageSize = 20

    func loadFeed() async {
        isLoading = true
        errorMessage = nil
        offset = 0

        // Refresh auth session so the JWT is valid before fetching
        _ = await SupabaseManager.shared.restoreSession()

        do {
            posts = try await PostService.shared.fetchFeed(limit: pageSize, offset: 0)
            offset = posts.count
        } catch is CancellationError {
            // Task was cancelled (e.g. tab switch, pull-to-refresh) — ignore silently
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession task cancelled — ignore silently
        } catch {
            print("[FeedVM] Failed to load feed: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        do {
            let newPosts = try await PostService.shared.fetchFeed(limit: pageSize, offset: offset)
            posts.append(contentsOf: newPosts)
            offset += newPosts.count
        } catch is CancellationError {
            // Ignore
        } catch let urlError as URLError where urlError.code == .cancelled {
            // Ignore
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMore = false
    }

    func toggleLike(for post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let isLiked = posts[index].isLikedByMe ?? false
        // Optimistic update
        posts[index].isLikedByMe = !isLiked
        posts[index].likesCount = (posts[index].likesCount ?? 0) + (isLiked ? -1 : 1)
        do {
            if isLiked {
                try await SocialService.shared.unlikePost(postId: post.id)
            } else {
                try await SocialService.shared.likePost(postId: post.id)
            }
        } catch {
            // Revert on failure
            posts[index].isLikedByMe = isLiked
            posts[index].likesCount = (posts[index].likesCount ?? 0) + (isLiked ? 1 : -1)
        }
    }


    // MARK: - Preview

    static var preview: FeedViewModel {
        let vm = FeedViewModel()
        vm.posts = Post.mockData
        return vm
    }
}
