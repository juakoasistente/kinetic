import Photos
import AVFoundation
import UIKit

struct VideoSaveHelper {

    /// Save video to Photos library and return the local identifier
    static func saveToPhotos(videoURL: URL) async -> String? {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            debugPrint("[VideoSave] Photo library access denied")
            return nil
        }

        var localIdentifier: String?

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                localIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
            }
        } catch {
            debugPrint("[VideoSave] Failed to save: \(error.localizedDescription)")
            return nil
        }

        return localIdentifier
    }

    /// Generate a thumbnail from a video URL
    static func generateThumbnail(videoURL: URL, at time: TimeInterval = 1.0) async -> UIImage? {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 600, height: 600)

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)

        do {
            let (cgImage, _) = try await generator.image(at: cmTime)
            return UIImage(cgImage: cgImage)
        } catch {
            debugPrint("[VideoSave] Thumbnail failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Fetch video URL from Photos by local identifier (for playback)
    static func fetchVideoURL(localIdentifier: String) async -> URL? {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            debugPrint("[VideoSave] Photo library read access denied")
            return nil
        }

        let results = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = results.firstObject else {
            debugPrint("[VideoSave] Asset not found for identifier: \(localIdentifier)")
            return nil
        }

        return await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    continuation.resume(returning: urlAsset.url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
