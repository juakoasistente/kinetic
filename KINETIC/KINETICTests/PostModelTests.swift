import Testing
import Foundation
@testable import KINETIC

struct PostModelTests {

    // MARK: - PostVisibility

    @Test func visibility_displayNames() {
        #expect(PostVisibility.public.displayName == "Public")
        #expect(PostVisibility.unlisted.displayName == "Unlisted")
        #expect(PostVisibility.private.displayName == "Private")
    }

    @Test func visibility_icons() {
        #expect(PostVisibility.public.icon == "globe")
        #expect(PostVisibility.unlisted.icon == "link")
        #expect(PostVisibility.private.icon == "lock.fill")
    }

    @Test func visibility_rawValues_matchDatabase() {
        #expect(PostVisibility.public.rawValue == "public")
        #expect(PostVisibility.unlisted.rawValue == "unlisted")
        #expect(PostVisibility.private.rawValue == "private")
    }

    @Test func visibility_codable_roundtrip() throws {
        for visibility in PostVisibility.allCases {
            let data = try JSONEncoder().encode(visibility)
            let decoded = try JSONDecoder().decode(PostVisibility.self, from: data)
            #expect(decoded == visibility)
        }
    }

    // MARK: - Post computed properties

    @Test func authorName_withAuthor() {
        let post = Post(
            userId: UUID(),
            author: Profile(id: UUID(), nickname: "Alex")
        )
        #expect(post.authorName == "Alex")
    }

    @Test func authorName_withoutAuthor() {
        let post = Post(userId: UUID())
        #expect(post.authorName == "Unknown")
    }

    @Test func authorAvatarUrl_withAuthor() {
        let post = Post(
            userId: UUID(),
            author: Profile(id: UUID(), avatarUrl: "https://example.com/avatar.jpg")
        )
        #expect(post.authorAvatarUrl == "https://example.com/avatar.jpg")
    }

    @Test func authorAvatarUrl_nil() {
        let post = Post(userId: UUID())
        #expect(post.authorAvatarUrl == nil)
    }

    // MARK: - Post equality by ID

    @Test func post_equalityById() {
        let id = UUID()
        let a = Post(id: id, userId: UUID(), description: "A")
        let b = Post(id: id, userId: UUID(), description: "B")
        #expect(a == b)
    }
}
