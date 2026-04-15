import Foundation
import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

@Observable
final class NewPostViewModel {
    var availableSessions: [Session] = []
    var selectedSession: Session?
    var postDescription = ""
    var visibility: PostVisibility = .public
    var selectedPhotos: [PhotosPickerItem] = [] {
        didSet { loadMedia() }
    }
    var selectedImages: [UIImage] = []
    var selectedVideoURLs: [URL] = []
    var videoThumbnails: [UIImage] = []
    var isPublishing = false
    var didPublish = false
    var errorMessage: String?

    var canPublish: Bool {
        !postDescription.trimmingCharacters(in: .whitespaces).isEmpty || selectedSession != nil
    }

    func loadSessions() async {
        guard let userId = SupabaseManager.shared.currentUserId else { return }
        do {
            availableSessions = try await SessionService.shared.fetchSessions(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func publish() async {
        guard canPublish else { return }
        guard let userId = SupabaseManager.shared.currentUserId else {
            errorMessage = "Not authenticated"
            return
        }

        isPublishing = true
        do {
            let post = Post(
                userId: userId,
                sessionId: selectedSession?.id,
                description: postDescription,
                visibility: visibility
            )

            let createdPost = try await PostService.shared.createPost(post)
            var mediaIndex = 0

            // Upload images
            for image in selectedImages {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    let url = try await PostService.shared.uploadPostImage(
                        postId: createdPost.id,
                        imageData: data,
                        index: mediaIndex
                    )
                    try await PostService.shared.addMedia(
                        postId: createdPost.id,
                        mediaUrl: url,
                        mediaType: .image,
                        sortOrder: mediaIndex
                    )
                    mediaIndex += 1
                }
            }

            // Upload videos
            for videoURL in selectedVideoURLs {
                let videoData = try Data(contentsOf: videoURL)
                let url = try await PostService.shared.uploadPostVideo(
                    postId: createdPost.id,
                    videoData: videoData,
                    index: mediaIndex
                )
                try await PostService.shared.addMedia(
                    postId: createdPost.id,
                    mediaUrl: url,
                    mediaType: .video,
                    sortOrder: mediaIndex
                )
                mediaIndex += 1
            }

            didPublish = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isPublishing = false
    }

    private func loadMedia() {
        Task { @MainActor in
            var images: [UIImage] = []
            var videoURLs: [URL] = []
            var thumbnails: [UIImage] = []

            for item in selectedPhotos {
                let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) })

                if isVideo {
                    if let movieData = try? await item.loadTransferable(type: Data.self) {
                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent("post_video_\(UUID().uuidString).mov")
                        try? movieData.write(to: tempURL)
                        videoURLs.append(tempURL)

                        if let thumbnail = await VideoSaveHelper.generateThumbnail(videoURL: tempURL) {
                            thumbnails.append(thumbnail)
                        }
                    }
                } else {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
            }

            selectedImages = images
            selectedVideoURLs = videoURLs
            videoThumbnails = thumbnails
        }
    }
}
