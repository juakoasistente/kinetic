import Foundation
import SwiftUI
import PhotosUI

@Observable
final class NewPostViewModel {
    var availableSessions: [Session] = []
    var selectedSession: Session?
    var postDescription = ""
    var visibility: PostVisibility = .public
    var selectedPhotos: [PhotosPickerItem] = [] {
        didSet { loadImages() }
    }
    var selectedImages: [UIImage] = []
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

            // Upload images
            for (index, image) in selectedImages.enumerated() {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    let url = try await PostService.shared.uploadPostImage(
                        postId: createdPost.id,
                        imageData: data,
                        index: index
                    )
                    try await PostService.shared.addMedia(
                        postId: createdPost.id,
                        mediaUrl: url,
                        mediaType: .image,
                        sortOrder: index
                    )
                }
            }

            didPublish = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isPublishing = false
    }

    private func loadImages() {
        Task { @MainActor in
            var images: [UIImage] = []
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            selectedImages = images
        }
    }
}
