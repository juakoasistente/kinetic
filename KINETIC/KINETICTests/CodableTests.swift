import Testing
import Foundation
@testable import KINETIC

struct CodableTests {

    // MARK: - Session snake_case decoding

    @Test func session_decodesFromSnakeCase() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "user_id": "00000000-0000-0000-0000-000000000002",
            "name": "Sierra Route",
            "category": "Performance",
            "vehicle": "BMW M3",
            "date": "2026-04-07T10:00:00Z",
            "distance": 42.8,
            "duration": 1452,
            "has_video": true,
            "thumbnail_url": "https://example.com/thumb.jpg",
            "video_url": "local-id-123",
            "location_name": "Barcelona, Spain",
            "created_at": "2026-04-07T10:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(Session.self, from: json.data(using: .utf8)!)

        #expect(session.name == "Sierra Route")
        #expect(session.userId == UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        #expect(session.hasVideo == true)
        #expect(session.thumbnailUrl == "https://example.com/thumb.jpg")
        #expect(session.videoUrl == "local-id-123")
        #expect(session.locationName == "Barcelona, Spain")
        #expect(session.distance == 42.8)
        #expect(session.duration == 1452)
    }

    // MARK: - Profile snake_case decoding

    @Test func profile_decodesFromSnakeCase() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "nickname": "Alex",
            "bio": "Car lover",
            "avatar_url": "https://example.com/avatar.jpg",
            "tier": "pro",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-04-07T00:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profile = try decoder.decode(Profile.self, from: json.data(using: .utf8)!)

        #expect(profile.nickname == "Alex")
        #expect(profile.bio == "Car lover")
        #expect(profile.avatarUrl == "https://example.com/avatar.jpg")
        #expect(profile.tier == "pro")
    }

    // MARK: - Post visibility Codable

    @Test func post_visibilityEncodesAsString() throws {
        let post = Post(userId: UUID(), visibility: .unlisted)
        let data = try JSONEncoder().encode(post)
        let jsonString = String(data: data, encoding: .utf8)!
        #expect(jsonString.contains("\"unlisted\""))
    }

    // MARK: - PostMedia snake_case

    @Test func postMedia_decodesFromSnakeCase() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "post_id": "00000000-0000-0000-0000-000000000002",
            "media_url": "https://example.com/photo.jpg",
            "media_type": "image",
            "sort_order": 2,
            "created_at": "2026-04-07T00:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let media = try decoder.decode(PostMedia.self, from: json.data(using: .utf8)!)

        #expect(media.mediaUrl == "https://example.com/photo.jpg")
        #expect(media.mediaType == .image)
        #expect(media.sortOrder == 2)
    }

    @Test func mediaType_decodesVideoCorrectly() throws {
        let data = try JSONEncoder().encode(MediaType.video)
        let decoded = try JSONDecoder().decode(MediaType.self, from: data)
        #expect(decoded == .video)
    }
}
