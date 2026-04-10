import Testing
import Foundation
@testable import KINETIC

struct CommentTests {

    @Test func authorName_withAuthor() {
        let comment = Comment(
            userId: UUID(),
            postId: UUID(),
            content: "Great!",
            author: Profile(id: UUID(), nickname: "Sara")
        )
        #expect(comment.authorName == "Sara")
    }

    @Test func authorName_withoutAuthor() {
        let comment = Comment(userId: UUID(), postId: UUID(), content: "Great!")
        #expect(comment.authorName == "Unknown")
    }

    @Test func equality_byId() {
        let id = UUID()
        let a = Comment(id: id, userId: UUID(), postId: UUID(), content: "A")
        let b = Comment(id: id, userId: UUID(), postId: UUID(), content: "B")
        #expect(a == b)
    }

    @Test func equality_differentId() {
        let a = Comment(userId: UUID(), postId: UUID(), content: "Same")
        let b = Comment(userId: UUID(), postId: UUID(), content: "Same")
        #expect(a != b)
    }
}
