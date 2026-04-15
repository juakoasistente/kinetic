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
        telemetrySnapshots: [TelemetrySnapshot],
        template: OverlayTemplate = .classic
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
            snapshots: telemetrySnapshots,
            template: template
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
        layerInstruction.setTransform(transform, at: .zero)
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
        snapshots: [TelemetrySnapshot],
        template: OverlayTemplate
    ) {
        guard let lastSnapshot = snapshots.last else { return }
        let stravaOrange = UIColor(red: 0.988, green: 0.322, blue: 0, alpha: 1)

        switch template {
        case .classic:
            addClassicOverlay(to: parentLayer, size: size, duration: duration, snapshots: snapshots, lastSnapshot: lastSnapshot, accent: stravaOrange)
        case .minimal:
            addMinimalOverlay(to: parentLayer, size: size, duration: duration, snapshots: snapshots, lastSnapshot: lastSnapshot, accent: stravaOrange)
        case .dashboard:
            addDashboardOverlay(to: parentLayer, size: size, duration: duration, snapshots: snapshots, lastSnapshot: lastSnapshot, accent: stravaOrange)
        }

        // KINETIC watermark — large, semi-transparent, centered
        let watermarkFontSize = size.width * 0.12
        let watermarkLayer = CATextLayer()
        watermarkLayer.string = "KINETIC"
        watermarkLayer.font = UIFont.systemFont(ofSize: watermarkFontSize, weight: .black)
        watermarkLayer.fontSize = watermarkFontSize
        watermarkLayer.foregroundColor = UIColor.white.withAlphaComponent(0.08).cgColor
        watermarkLayer.alignmentMode = .center
        watermarkLayer.contentsScale = UIScreen.main.scale
        watermarkLayer.frame = CGRect(x: 0, y: (size.height - watermarkFontSize) / 2, width: size.width, height: watermarkFontSize * 1.3)
        parentLayer.addSublayer(watermarkLayer)

        // Small KINETIC branding — top right
        let padding: CGFloat = size.width * 0.04
        let brandLayer = makeLabel(
            text: "KINETIC", fontSize: size.width * 0.025,
            color: stravaOrange.withAlphaComponent(0.6),
            frame: CGRect(x: size.width - size.width * 0.18 - padding, y: size.height - padding - size.width * 0.035, width: size.width * 0.18, height: size.width * 0.035),
            bold: true, alignment: .right
        )
        parentLayer.addSublayer(brandLayer)
    }

    // MARK: - Classic: big speed centered, stats row, gradient bottom

    private static func addClassicOverlay(to parentLayer: CALayer, size: CGSize, duration: Double, snapshots: [TelemetrySnapshot], lastSnapshot: TelemetrySnapshot, accent: UIColor) {
        let padding: CGFloat = size.width * 0.04

        // Gradient at bottom
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.4)
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        parentLayer.addSublayer(gradientLayer)

        // Big speed — center bottom
        let speedFontSize = size.width * 0.1
        let speedValue = makeLabel(
            text: "\(Int(lastSnapshot.speed))", fontSize: speedFontSize, color: .white,
            frame: CGRect(x: 0, y: size.height * 0.14, width: size.width, height: speedFontSize * 1.2),
            bold: true, alignment: .center
        )
        parentLayer.addSublayer(speedValue)
        addSpeedAnimation(to: speedValue, snapshots: snapshots, duration: duration, format: "%d")

        let unitLayer = makeLabel(
            text: "KM/H", fontSize: size.width * 0.03, color: accent,
            frame: CGRect(x: 0, y: size.height * 0.1, width: size.width, height: size.width * 0.04),
            bold: true, alignment: .center
        )
        parentLayer.addSublayer(unitLayer)

        // Stats row
        let barY: CGFloat = size.height * 0.03
        let statWidth = (size.width - padding * 4) / 3
        let stats: [(String, String)] = [
            ("MAX", "\(Int(lastSnapshot.maxSpeed)) KM/H"),
            ("DIST", String(format: "%.1f KM", lastSnapshot.distance)),
            ("TIME", formatTime(lastSnapshot.elapsed))
        ]
        for (i, stat) in stats.enumerated() {
            let x = padding + CGFloat(i) * (statWidth + padding)
            let label = makeLabel(text: stat.0, fontSize: size.width * 0.022, color: .white.withAlphaComponent(0.6), frame: CGRect(x: x, y: barY + size.width * 0.04, width: statWidth, height: size.width * 0.03))
            let value = makeLabel(text: stat.1, fontSize: size.width * 0.04, color: .white, frame: CGRect(x: x, y: barY, width: statWidth, height: size.width * 0.045), bold: true)
            parentLayer.addSublayer(label)
            parentLayer.addSublayer(value)
        }

        // Time top-right
        let timeBg = CALayer()
        let timeW = size.width * 0.2
        timeBg.frame = CGRect(x: size.width - timeW - padding, y: size.height - padding - size.width * 0.06, width: timeW, height: size.width * 0.05)
        timeBg.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
        timeBg.cornerRadius = size.width * 0.025
        parentLayer.addSublayer(timeBg)
        let timeLabel = makeLabel(
            text: formatTime(lastSnapshot.elapsed), fontSize: size.width * 0.025, color: .white,
            frame: timeBg.frame, bold: true, alignment: .center
        )
        parentLayer.addSublayer(timeLabel)
        addTimeAnimation(to: timeLabel, snapshots: snapshots, duration: duration)
    }

    // MARK: - Minimal: speed bottom-left, time top-right

    private static func addMinimalOverlay(to parentLayer: CALayer, size: CGSize, duration: Double, snapshots: [TelemetrySnapshot], lastSnapshot: TelemetrySnapshot, accent: UIColor) {
        let padding: CGFloat = size.width * 0.05

        // Speed — bottom left, big
        let speedFontSize = size.width * 0.09
        let speedValue = makeLabel(
            text: "\(Int(lastSnapshot.speed))", fontSize: speedFontSize, color: .white,
            frame: CGRect(x: padding, y: padding + size.width * 0.025, width: size.width * 0.4, height: speedFontSize * 1.2),
            bold: true
        )
        parentLayer.addSublayer(speedValue)
        addSpeedAnimation(to: speedValue, snapshots: snapshots, duration: duration, format: "%d")

        let unitLayer = makeLabel(
            text: "KM/H", fontSize: size.width * 0.025, color: accent,
            frame: CGRect(x: padding, y: padding, width: size.width * 0.2, height: size.width * 0.03),
            bold: true
        )
        parentLayer.addSublayer(unitLayer)

        // Time — top right
        let timeBg = CALayer()
        let timeW = size.width * 0.22
        timeBg.frame = CGRect(x: size.width - timeW - padding, y: size.height - padding - size.width * 0.06, width: timeW, height: size.width * 0.05)
        timeBg.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
        timeBg.cornerRadius = size.width * 0.025
        parentLayer.addSublayer(timeBg)
        let timeLabel = makeLabel(
            text: formatTime(lastSnapshot.elapsed), fontSize: size.width * 0.025, color: .white,
            frame: timeBg.frame, bold: true, alignment: .center
        )
        parentLayer.addSublayer(timeLabel)
        addTimeAnimation(to: timeLabel, snapshots: snapshots, duration: duration)
    }

    // MARK: - Dashboard: speed big centered orange, stats bar bottom

    private static func addDashboardOverlay(to parentLayer: CALayer, size: CGSize, duration: Double, snapshots: [TelemetrySnapshot], lastSnapshot: TelemetrySnapshot, accent: UIColor) {
        let padding: CGFloat = size.width * 0.04

        // Speed — big, center, orange
        let speedFontSize = size.width * 0.12
        let speedValue = makeLabel(
            text: "\(Int(lastSnapshot.speed))", fontSize: speedFontSize, color: accent,
            frame: CGRect(x: 0, y: (size.height - speedFontSize) / 2, width: size.width, height: speedFontSize * 1.2),
            bold: true, alignment: .center
        )
        parentLayer.addSublayer(speedValue)
        addSpeedAnimation(to: speedValue, snapshots: snapshots, duration: duration, format: "%d")

        let unitLayer = makeLabel(
            text: "KM/H", fontSize: size.width * 0.025, color: .white.withAlphaComponent(0.5),
            frame: CGRect(x: 0, y: (size.height - speedFontSize) / 2 - size.width * 0.035, width: size.width, height: size.width * 0.03),
            bold: true, alignment: .center
        )
        parentLayer.addSublayer(unitLayer)

        // Stats bar at bottom
        let barHeight: CGFloat = size.height * 0.1
        let barLayer = CALayer()
        barLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: barHeight)
        barLayer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
        parentLayer.addSublayer(barLayer)

        let statWidth = (size.width - padding * 5) / 4
        let stats: [(String, String)] = [
            ("MAX", "\(Int(lastSnapshot.maxSpeed))"),
            ("AVG", "\(Int(lastSnapshot.avgSpeed))"),
            ("DIST", String(format: "%.1f", lastSnapshot.distance)),
            ("TIME", formatTime(lastSnapshot.elapsed))
        ]
        for (i, stat) in stats.enumerated() {
            let x = padding + CGFloat(i) * (statWidth + padding)
            let label = makeLabel(text: stat.0, fontSize: size.width * 0.02, color: accent.withAlphaComponent(0.7), frame: CGRect(x: x, y: barHeight * 0.55, width: statWidth, height: barHeight * 0.3))
            let value = makeLabel(text: stat.1, fontSize: size.width * 0.035, color: .white, frame: CGRect(x: x, y: barHeight * 0.15, width: statWidth, height: barHeight * 0.4), bold: true)
            barLayer.addSublayer(label)
            barLayer.addSublayer(value)
        }
    }

    // MARK: - Animation Helpers

    private static func addSpeedAnimation(to layer: CALayer, snapshots: [TelemetrySnapshot], duration: Double, format: String) {
        guard snapshots.count > 1 else { return }
        let animation = CAKeyframeAnimation(keyPath: "string")
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.calculationMode = .discrete
        animation.keyTimes = snapshots.map { NSNumber(value: $0.timestamp / duration) }
        animation.values = snapshots.map { String(format: format, Int($0.speed)) }
        (layer as? CATextLayer)?.add(animation, forKey: "speedAnim")
    }

    private static func addTimeAnimation(to layer: CALayer, snapshots: [TelemetrySnapshot], duration: Double) {
        guard snapshots.count > 1 else { return }
        let animation = CAKeyframeAnimation(keyPath: "string")
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.calculationMode = .discrete
        animation.keyTimes = snapshots.map { NSNumber(value: $0.timestamp / duration) }
        animation.values = snapshots.map { formatTime($0.elapsed) }
        (layer as? CATextLayer)?.add(animation, forKey: "timeAnim")
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
