import AVFoundation
import UIKit
import CoreImage

/// Exports a video with telemetry overlay burned in, synced from a GPX track.
final class VideoExporter {
    
    // MARK: - Types
    
    enum ExportError: Error, LocalizedError {
        case invalidVideoURL
        case noVideoTrack
        case noGPXData
        case exportFailed(String)
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .invalidVideoURL: return "Invalid video URL"
            case .noVideoTrack: return "No video track found"
            case .noGPXData: return "No GPX data loaded"
            case .exportFailed(let msg): return "Export failed: \(msg)"
            case .cancelled: return "Export cancelled"
            }
        }
    }
    
    struct ExportConfig {
        var videoURL: URL
        var gpxTrack: GPXParser.GPXTrack
        var overlayConfig: OverlayRenderer.OverlayConfig
        var timeOffset: TimeInterval = 0  // Offset between video start and GPX start (seconds)
        var outputQuality: OutputQuality = .high
        
        enum OutputQuality {
            case medium  // 720p
            case high    // 1080p
            case original // Same as input
        }
    }
    
    // MARK: - Progress
    
    var progress: Float = 0
    var isExporting: Bool = false
    
    private var exportSession: AVAssetExportSession?
    
    // MARK: - Export
    
    /// Export video with overlay. Returns URL to the exported file.
    func export(config: ExportConfig) async throws -> URL {
        isExporting = true
        progress = 0
        
        defer { isExporting = false }
        
        let asset = AVAsset(url: config.videoURL)
        
        // Get video track
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw ExportError.noVideoTrack
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let transform = try await videoTrack.load(.preferredTransform)
        let duration = try await asset.load(.duration)
        
        // Determine actual video size (accounting for transform/rotation)
        let videoSize = applyTransform(naturalSize, transform: transform)
        
        // Create composition
        let composition = AVMutableComposition()
        
        // Add video track
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { throw ExportError.exportFailed("Could not create video track") }
        
        try compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: videoTrack,
            at: .zero
        )
        compositionVideoTrack.preferredTransform = transform
        
        // Add audio track if present
        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            if let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) {
                try compositionAudioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: duration),
                    of: audioTrack,
                    at: .zero
                )
            }
        }
        
        // Create video composition with overlay
        let videoComposition = AVMutableVideoComposition(
            propertiesOf: composition
        )
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // 30fps
        
        // Custom compositor for overlay
        videoComposition.customVideoCompositorClass = OverlayCompositor.self
        
        // Store overlay config in a shared place the compositor can access
        OverlayCompositor.shared.gpxTrack = config.gpxTrack
        OverlayCompositor.shared.overlayConfig = config.overlayConfig
        OverlayCompositor.shared.timeOffset = config.timeOffset
        OverlayCompositor.shared.videoSize = videoSize
        
        // Create instruction
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        // Output URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetic_\(UUID().uuidString).mp4")
        
        // Remove existing file
        try? FileManager.default.removeItem(at: outputURL)
        
        // Export
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: exportPreset(for: config.outputQuality, videoSize: videoSize)
        ) else { throw ExportError.exportFailed("Could not create export session") }
        
        self.exportSession = exportSession
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Monitor progress
        let progressTask = Task {
            while !Task.isCancelled && exportSession.status == .exporting {
                progress = exportSession.progress
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
        }
        
        await exportSession.export()
        progressTask.cancel()
        progress = 1.0
        
        switch exportSession.status {
        case .completed:
            return outputURL
        case .cancelled:
            throw ExportError.cancelled
        default:
            throw ExportError.exportFailed(exportSession.error?.localizedDescription ?? "Unknown error")
        }
    }
    
    /// Cancel ongoing export
    func cancel() {
        exportSession?.cancelExport()
    }
    
    // MARK: - Helpers
    
    private func applyTransform(_ size: CGSize, transform: CGAffineTransform) -> CGSize {
        let rect = CGRect(origin: .zero, size: size).applying(transform)
        return CGSize(width: abs(rect.width), height: abs(rect.height))
    }
    
    private func exportPreset(for quality: ExportConfig.OutputQuality, videoSize: CGSize) -> String {
        switch quality {
        case .medium: return AVAssetExportPreset1280x720
        case .high: return AVAssetExportPreset1920x1080
        case .original: return AVAssetExportPresetHighestQuality
        }
    }
}

// MARK: - Overlay Compositor

/// Custom video compositor that renders telemetry overlay on each frame.
final class OverlayCompositor: NSObject, AVVideoCompositing {
    
    static let shared = OverlayCompositor()
    
    var gpxTrack: GPXParser.GPXTrack?
    var overlayConfig = OverlayRenderer.OverlayConfig()
    var timeOffset: TimeInterval = 0
    var videoSize: CGSize = .zero
    
    // MARK: - AVVideoCompositing
    
    var sourcePixelBufferAttributes: [String: Any]? {
        [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    }
    
    var requiredPixelBufferAttributesForRenderContext: [String: Any] {
        [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    }
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}
    
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard let sourceBuffer = asyncVideoCompositionRequest.sourceFrame(
            byTrackID: asyncVideoCompositionRequest.sourceTrackIDs.first?.int32Value ?? 0
        ) else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "OverlayCompositor", code: -1))
            return
        }
        
        let time = CMTimeGetSeconds(asyncVideoCompositionRequest.compositionTime)
        
        // Get interpolated GPX data for this frame
        let gpxTime = time + timeOffset
        
        if let track = gpxTrack, let data = track.dataAt(timeOffset: gpxTime) {
            // Render overlay
            if let overlayImage = OverlayRenderer.renderOverlay(
                data: data,
                videoSize: videoSize,
                config: overlayConfig
            ) {
                // Composite overlay onto video frame
                if let outputBuffer = compositeOverlay(overlayImage, onto: sourceBuffer) {
                    asyncVideoCompositionRequest.finish(withComposedVideoFrame: outputBuffer)
                    return
                }
            }
        }
        
        // If no overlay needed, pass through original frame
        asyncVideoCompositionRequest.finish(withComposedVideoFrame: sourceBuffer)
    }
    
    func cancelAllPendingVideoCompositionRequests() {}
    
    // MARK: - Compositing
    
    private func compositeOverlay(_ overlay: UIImage, onto pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let overlayCIImage = CIImage(image: overlay) else { return pixelBuffer }
        
        let composited = overlayCIImage.composited(over: ciImage)
        
        let context = CIContext()
        var outputBuffer: CVPixelBuffer?
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            nil,
            &outputBuffer
        )
        
        guard let output = outputBuffer else { return pixelBuffer }
        context.render(composited, to: output)
        
        return output
    }
}
