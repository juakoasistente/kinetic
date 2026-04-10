import AVFoundation
import UIKit
import CoreGraphics

struct OverlayCompositor {

    struct TelemetrySnapshot {
        let timestamp: TimeInterval
        let speed: Double
        let maxSpeed: Double
        let avgSpeed: Double
        let distance: Double
        let elapsed: TimeInterval
    }

    /// Compose telemetry overlay onto a recorded video
    static func composeOverlay(
        videoURL: URL,
        telemetrySnapshots: [TelemetrySnapshot]
    ) async -> URL? {
        let asset = AVURLAsset(url: videoURL)

        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            debugPrint("[OverlayCompositor] No video track found")
            return nil
        }

        let duration = try? await asset.load(.duration)
        let naturalSize = try? await videoTrack.load(.naturalSize)
        let transform = try? await videoTrack.load(.preferredTransform)

        guard let duration, let naturalSize, let transform else { return nil }

        // Calculate actual video size accounting for rotation
        let videoSize: CGSize
        let isPortrait = abs(transform.a) < 0.01
        if isPortrait {
            videoSize = CGSize(width: naturalSize.height, height: naturalSize.width)
        } else {
            videoSize = naturalSize
        }

        // Create composition
        let composition = AVMutableComposition()

        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return nil }

        let timeRange = CMTimeRange(start: .zero, duration: duration)
        try? compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        compositionVideoTrack.preferredTransform = transform

        // Add audio if available
        if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }

        // Create overlay layer
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)

        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)

        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)

        // Add telemetry frames as animation
        addTelemetryOverlay(
            to: overlayLayer,
            size: videoSize,
            duration: duration.seconds,
            snapshots: telemetrySnapshots
        )

        // Video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        // Export
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetic_overlay_\(UUID().uuidString).mov")

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { return nil }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition

        await exportSession.export()

        if exportSession.status == .completed {
            return outputURL
        } else {
            debugPrint("[OverlayCompositor] Export failed: \(exportSession.error?.localizedDescription ?? "unknown")")
            return nil
        }
    }

    // MARK: - Overlay Rendering

    private static func addTelemetryOverlay(
        to parentLayer: CALayer,
        size: CGSize,
        duration: Double,
        snapshots: [TelemetrySnapshot]
    ) {
        guard let lastSnapshot = snapshots.last else { return }

        // Background bar at bottom
        let barHeight: CGFloat = size.height * 0.15
        let barLayer = CALayer()
        barLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: barHeight)
        barLayer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
        parentLayer.addSublayer(barLayer)

        let padding: CGFloat = size.width * 0.04
        let statWidth = (size.width - padding * 5) / 4

        // Speed (animated via keyframes)
        let speedLabel = makeLabel(
            text: "SPEED",
            fontSize: size.width * 0.025,
            color: .white.withAlphaComponent(0.6),
            frame: CGRect(x: padding, y: barHeight * 0.55, width: statWidth, height: barHeight * 0.3)
        )
        barLayer.addSublayer(speedLabel)

        let speedValue = makeLabel(
            text: "\(Int(lastSnapshot.speed)) KM/H",
            fontSize: size.width * 0.045,
            color: .white,
            frame: CGRect(x: padding, y: barHeight * 0.15, width: statWidth, height: barHeight * 0.4),
            bold: true
        )
        barLayer.addSublayer(speedValue)

        // Animate speed text
        if snapshots.count > 1 {
            let animation = CAKeyframeAnimation(keyPath: "string")
            animation.beginTime = AVCoreAnimationBeginTimeAtZero
            animation.duration = duration
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            animation.calculationMode = .discrete

            var keyTimes: [NSNumber] = []
            var values: [String] = []
            for snap in snapshots {
                keyTimes.append(NSNumber(value: snap.timestamp / duration))
                values.append("\(Int(snap.speed)) KM/H")
            }
            animation.keyTimes = keyTimes
            animation.values = values

            (speedValue as? CATextLayer)?.add(animation, forKey: "speedAnim")
        }

        // Max Speed (static)
        let maxLabel = makeLabel(
            text: "MAX",
            fontSize: size.width * 0.025,
            color: .white.withAlphaComponent(0.6),
            frame: CGRect(x: padding * 2 + statWidth, y: barHeight * 0.55, width: statWidth, height: barHeight * 0.3)
        )
        barLayer.addSublayer(maxLabel)

        let maxValue = makeLabel(
            text: "\(Int(lastSnapshot.maxSpeed)) KM/H",
            fontSize: size.width * 0.045,
            color: .white,
            frame: CGRect(x: padding * 2 + statWidth, y: barHeight * 0.15, width: statWidth, height: barHeight * 0.4),
            bold: true
        )
        barLayer.addSublayer(maxValue)

        // Distance (animated)
        let distLabel = makeLabel(
            text: "DIST",
            fontSize: size.width * 0.025,
            color: .white.withAlphaComponent(0.6),
            frame: CGRect(x: padding * 3 + statWidth * 2, y: barHeight * 0.55, width: statWidth, height: barHeight * 0.3)
        )
        barLayer.addSublayer(distLabel)

        let distValue = makeLabel(
            text: String(format: "%.1f KM", lastSnapshot.distance),
            fontSize: size.width * 0.045,
            color: .white,
            frame: CGRect(x: padding * 3 + statWidth * 2, y: barHeight * 0.15, width: statWidth, height: barHeight * 0.4),
            bold: true
        )
        barLayer.addSublayer(distValue)

        // Time (animated)
        let timeLabel = makeLabel(
            text: "TIME",
            fontSize: size.width * 0.025,
            color: .white.withAlphaComponent(0.6),
            frame: CGRect(x: padding * 4 + statWidth * 3, y: barHeight * 0.55, width: statWidth, height: barHeight * 0.3)
        )
        barLayer.addSublayer(timeLabel)

        let timeValue = makeLabel(
            text: formatTime(lastSnapshot.elapsed),
            fontSize: size.width * 0.045,
            color: .white,
            frame: CGRect(x: padding * 4 + statWidth * 3, y: barHeight * 0.15, width: statWidth, height: barHeight * 0.4),
            bold: true
        )
        barLayer.addSublayer(timeValue)

        // KINETIC watermark — large, semi-transparent, centered
        // Only visible in exported video, NOT in live preview
        let watermarkFontSize = size.width * 0.12
        let watermarkText = "KINETIC"
        let watermarkLayer = CATextLayer()
        watermarkLayer.string = watermarkText
        watermarkLayer.font = UIFont.systemFont(ofSize: watermarkFontSize, weight: .black)
        watermarkLayer.fontSize = watermarkFontSize
        watermarkLayer.foregroundColor = UIColor.white.withAlphaComponent(0.08).cgColor
        watermarkLayer.alignmentMode = .center
        watermarkLayer.contentsScale = UIScreen.main.scale
        watermarkLayer.frame = CGRect(
            x: 0,
            y: (size.height - watermarkFontSize) / 2,
            width: size.width,
            height: watermarkFontSize * 1.3
        )
        parentLayer.addSublayer(watermarkLayer)

        // Small KINETIC branding — top right corner
        let brandLayer = makeLabel(
            text: "KINETIC",
            fontSize: size.width * 0.025,
            color: UIColor(red: 0.988, green: 0.322, blue: 0, alpha: 0.6),
            frame: CGRect(x: size.width - size.width * 0.18 - padding, y: size.height - padding - size.width * 0.035, width: size.width * 0.18, height: size.width * 0.035),
            bold: true,
            alignment: .right
        )
        parentLayer.addSublayer(brandLayer)
    }

    private static func makeLabel(
        text: String,
        fontSize: CGFloat,
        color: UIColor,
        frame: CGRect,
        bold: Bool = false,
        alignment: CATextLayerAlignmentMode = .left
    ) -> CATextLayer {
        let layer = CATextLayer()
        layer.string = text
        layer.font = bold ? UIFont.systemFont(ofSize: fontSize, weight: .bold) : UIFont.systemFont(ofSize: fontSize, weight: .medium)
        layer.fontSize = fontSize
        layer.foregroundColor = color.cgColor
        layer.frame = frame
        layer.alignmentMode = alignment
        layer.contentsScale = UIScreen.main.scale
        layer.isWrapped = false
        layer.truncationMode = .none
        return layer
    }

    private static func formatTime(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
