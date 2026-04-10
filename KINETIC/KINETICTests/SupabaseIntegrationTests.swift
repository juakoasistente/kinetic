import Testing
import Foundation
@testable import KINETIC

/// Integration tests that hit the real Supabase backend.
/// These require network access and a configured Supabase client.
struct SupabaseIntegrationTests {

    // MARK: - Client Configuration

    @Test func supabaseClient_isConfigured() {
        #expect(SupabaseManager.shared.isConfigured == true)
        #expect(SupabaseManager.shared.client != nil)
    }

    // MARK: - Session CRUD

    @Test func sessionService_createReadDelete() async throws {
        let client = SupabaseManager.shared.client
        try #require(client != nil, "Supabase not configured")

        // We need a user ID — use a fake one for RLS bypass won't work
        // Instead, test that the service methods exist and throw appropriate errors
        // when not authenticated (no currentUserId)
        let userId = SupabaseManager.shared.currentUserId

        if let userId {
            // User is authenticated — do full CRUD
            let sessionId = UUID()
            let session = Session(
                id: sessionId,
                userId: userId,
                name: "Integration Test Session",
                date: Date(),
                distance: 10.5,
                duration: 600
            )

            // Create
            try await SessionService.shared.createSession(session)

            // Read
            let sessions = try await SessionService.shared.fetchSessions(userId: userId)
            let found = sessions.contains(where: { $0.id == sessionId })
            #expect(found == true, "Created session should appear in fetch")

            // Delete
            try await SessionService.shared.deleteSession(id: sessionId)

            // Verify deleted
            let afterDelete = try await SessionService.shared.fetchSessions(userId: userId)
            let stillExists = afterDelete.contains(where: { $0.id == sessionId })
            #expect(stillExists == false, "Deleted session should not appear")
        } else {
            // Not authenticated — just verify service doesn't crash
            // fetchSessions should throw ServiceError.notConfigured or similar
            print("[IntegrationTest] No authenticated user, skipping CRUD test")
        }
    }

    // MARK: - Telemetry with Snapshots

    @Test func telemetryService_saveWithSnapshots() async throws {
        let client = SupabaseManager.shared.client
        try #require(client != nil, "Supabase not configured")

        guard let userId = SupabaseManager.shared.currentUserId else {
            print("[IntegrationTest] No authenticated user, skipping telemetry test")
            return
        }

        // Create a temporary session first
        let sessionId = UUID()
        let session = Session(
            id: sessionId,
            userId: userId,
            name: "Telemetry Test",
            date: Date(),
            distance: 5.0,
            duration: 120
        )
        try await SessionService.shared.createSession(session)

        // Create telemetry with snapshots
        let snapshots = (0..<10).map { i -> TelemetrySnapshot in
            let ts = TimeInterval(i)
            return TelemetrySnapshot(
                timestamp: ts,
                speed: Double(i) * 10,
                maxSpeed: Double(i) * 10,
                avgSpeed: Double(i) * 5,
                distance: Double(i) * 0.1,
                elevation: 100,
                latitude: 41.389 + Double(i) * 0.0001,
                longitude: 2.174 + Double(i) * 0.0001
            )
        }

        let telemetry = DBTelemetryData(
            sessionId: sessionId,
            maxSpeed: 90,
            avgSpeed: 45,
            distance: 5.0,
            snapshots: snapshots
        )

        // Save
        try await TelemetryService.shared.saveTelemetry(telemetry)

        // Read back
        let fetched = try await TelemetryService.shared.fetchTelemetry(sessionId: sessionId)
        #expect(fetched != nil, "Telemetry should be fetchable")
        #expect(fetched?.maxSpeed == 90)
        #expect(fetched?.snapshots?.count == 10, "Snapshots should be persisted")
        #expect(fetched?.snapshots?.last?.speed == 90)

        // Cleanup
        try await SessionService.shared.deleteSession(id: sessionId)
    }

    // MARK: - Profile

    @Test func profileService_fetchProfile() async throws {
        let client = SupabaseManager.shared.client
        try #require(client != nil, "Supabase not configured")

        guard let userId = SupabaseManager.shared.currentUserId else {
            print("[IntegrationTest] No authenticated user, skipping profile test")
            return
        }

        let profile = try await ProfileService.shared.fetchProfile(userId: userId)
        #expect(profile.id == userId)
        // Profile should exist because trigger creates it on signup
    }

    // MARK: - Search

    @Test func sessionService_search() async throws {
        let client = SupabaseManager.shared.client
        try #require(client != nil, "Supabase not configured")

        guard let userId = SupabaseManager.shared.currentUserId else {
            print("[IntegrationTest] No authenticated user, skipping search test")
            return
        }

        // Create a session with a unique name
        let sessionId = UUID()
        let uniqueName = "SearchTest_\(UUID().uuidString.prefix(8))"
        let session = Session(
            id: sessionId,
            userId: userId,
            name: uniqueName,
            date: Date(),
            distance: 1.0,
            duration: 60
        )
        try await SessionService.shared.createSession(session)

        // Search for it
        let results = try await SessionService.shared.searchSessions(userId: userId, query: uniqueName)
        #expect(results.contains(where: { $0.id == sessionId }), "Search should find the session")

        // Cleanup
        try await SessionService.shared.deleteSession(id: sessionId)
    }

    // MARK: - Social Tables (Posts)

    @Test func postService_createAndDelete() async throws {
        let client = SupabaseManager.shared.client
        try #require(client != nil, "Supabase not configured")

        guard let userId = SupabaseManager.shared.currentUserId else {
            print("[IntegrationTest] No authenticated user, skipping post test")
            return
        }

        // Create post
        let post = Post(
            userId: userId,
            description: "Integration test post",
            visibility: .public
        )

        let created = try await PostService.shared.createPost(post)
        #expect(created.userId == userId)
        #expect(created.description == "Integration test post")

        // Delete
        try await PostService.shared.deletePost(id: created.id)
    }

    // MARK: - Social: Likes & Comments

    @Test func socialService_likeAndComment() async throws {
        let client = SupabaseManager.shared.client
        try #require(client != nil, "Supabase not configured")

        guard let userId = SupabaseManager.shared.currentUserId else {
            print("[IntegrationTest] No authenticated user, skipping social test")
            return
        }

        // Create a post to interact with
        let post = Post(userId: userId, description: "Social test", visibility: .public)
        let created = try await PostService.shared.createPost(post)

        // Like
        try await SocialService.shared.likePost(postId: created.id)
        let isLiked = try await SocialService.shared.isPostLiked(postId: created.id)
        #expect(isLiked == true)

        // Unlike
        try await SocialService.shared.unlikePost(postId: created.id)
        let isUnliked = try await SocialService.shared.isPostLiked(postId: created.id)
        #expect(isUnliked == false)

        // Comment
        let comment = try await SocialService.shared.addComment(postId: created.id, content: "Test comment")
        #expect(comment.content == "Test comment")

        // Fetch comments
        let comments = try await SocialService.shared.fetchComments(postId: created.id)
        #expect(comments.count >= 1)

        // Delete comment
        try await SocialService.shared.deleteComment(id: comment.id)

        // Cleanup
        try await PostService.shared.deletePost(id: created.id)
    }

    // MARK: - Bookmarks

    @Test func socialService_bookmark() async throws {
        let client = SupabaseManager.shared.client
        try #require(client != nil, "Supabase not configured")

        guard let userId = SupabaseManager.shared.currentUserId else {
            print("[IntegrationTest] No authenticated user, skipping bookmark test")
            return
        }

        let post = Post(userId: userId, description: "Bookmark test", visibility: .public)
        let created = try await PostService.shared.createPost(post)

        // Bookmark
        try await SocialService.shared.bookmarkPost(postId: created.id)

        // Unbookmark
        try await SocialService.shared.unbookmarkPost(postId: created.id)

        // Cleanup
        try await PostService.shared.deletePost(id: created.id)
    }
}
