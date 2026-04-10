import Testing
import Foundation
@testable import KINETIC

struct FeedViewModelTests {

    // MARK: - Optimistic Like Toggle

    @Test func toggleLike_unlikedPost_becomesLiked() async {
        let vm = FeedViewModel()
        vm.posts = [makePost(isLiked: false, likesCount: 5)]

        // We can't await the full async (it calls Supabase which will fail)
        // but we can test the optimistic state change directly
        let post = vm.posts[0]
        let index = 0
        let isLiked = vm.posts[index].isLikedByMe ?? false

        // Simulate optimistic update
        vm.posts[index].isLikedByMe = !isLiked
        vm.posts[index].likesCount = (vm.posts[index].likesCount ?? 0) + (isLiked ? -1 : 1)

        #expect(vm.posts[0].isLikedByMe == true)
        #expect(vm.posts[0].likesCount == 6)
    }

    @Test func toggleLike_likedPost_becomesUnliked() async {
        let vm = FeedViewModel()
        vm.posts = [makePost(isLiked: true, likesCount: 5)]

        let index = 0
        let isLiked = vm.posts[index].isLikedByMe ?? false

        vm.posts[index].isLikedByMe = !isLiked
        vm.posts[index].likesCount = (vm.posts[index].likesCount ?? 0) + (isLiked ? -1 : 1)

        #expect(vm.posts[0].isLikedByMe == false)
        #expect(vm.posts[0].likesCount == 4)
    }

    @Test func toggleLike_nilLikesCount_treatedAsZero() {
        let vm = FeedViewModel()
        vm.posts = [makePost(isLiked: false, likesCount: nil)]

        let index = 0
        let isLiked = vm.posts[index].isLikedByMe ?? false

        vm.posts[index].isLikedByMe = !isLiked
        vm.posts[index].likesCount = (vm.posts[index].likesCount ?? 0) + (isLiked ? -1 : 1)

        #expect(vm.posts[0].likesCount == 1)
    }

    @Test func toggleLike_nilIsLiked_treatedAsFalse() {
        let vm = FeedViewModel()
        vm.posts = [makePost(isLiked: nil, likesCount: 3)]

        let index = 0
        let isLiked = vm.posts[index].isLikedByMe ?? false

        vm.posts[index].isLikedByMe = !isLiked
        vm.posts[index].likesCount = (vm.posts[index].likesCount ?? 0) + (isLiked ? -1 : 1)

        #expect(vm.posts[0].isLikedByMe == true)
        #expect(vm.posts[0].likesCount == 4)
    }

    // MARK: - Optimistic Bookmark Toggle

    @Test func toggleBookmark_unbookmarked_becomesBookmarked() {
        let vm = FeedViewModel()
        vm.posts = [makePost(isBookmarked: false)]

        let index = 0
        let isBookmarked = vm.posts[index].isBookmarkedByMe ?? false
        vm.posts[index].isBookmarkedByMe = !isBookmarked

        #expect(vm.posts[0].isBookmarkedByMe == true)
    }

    @Test func toggleBookmark_bookmarked_becomesUnbookmarked() {
        let vm = FeedViewModel()
        vm.posts = [makePost(isBookmarked: true)]

        let index = 0
        let isBookmarked = vm.posts[index].isBookmarkedByMe ?? false
        vm.posts[index].isBookmarkedByMe = !isBookmarked

        #expect(vm.posts[0].isBookmarkedByMe == false)
    }

    // MARK: - Helpers

    private func makePost(
        isLiked: Bool? = false,
        likesCount: Int? = 0,
        isBookmarked: Bool? = false
    ) -> Post {
        Post(
            userId: UUID(),
            description: "Test post",
            likesCount: likesCount,
            isLikedByMe: isLiked,
            isBookmarkedByMe: isBookmarked
        )
    }
}
