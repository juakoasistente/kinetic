import AVFoundation
import UIKit
import CoreGraphics

struct ReelCompositor {

    struct ReelConfig {
        let videoURL: URL
        let clips: [ClipSelection]
        let tripName: String
        let maxSpeed: String
        let avgSpeed: String
        let distance: String
        let time: String
        let mapSnapshot: UIImage?
        let routePoints: [CGPoint]
    }

    /// Generate a reel: intro (2s) + selected clips + summary (5s)
    /// Output: 9:16 vertical video at 1080x1920
    static func generateReel(config: ReelConfig) async -> URL? {
        let reelSize = CGSize(width: 1080, height: 1920)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetic_reel_\(UUID().uuidString).mov")

        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mov) else { return nil }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(reelSize.width),
            AVVideoHeightKey: Int(reelSize.height),
        ]

        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(reelSize.width),
                kCVPixelBufferHeightKey as String: Int(reelSize.height),
            ]
        )

        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let fps: Int32 = 30
        var frameCount: Int64 = 0

        // 1. INTRO — 2 seconds (60 frames)
        let introFrames = 60
        for i in 0..<introFrames {
            let progress = Float(i) / Float(introFrames)
            let image = renderIntroFrame(
                size: reelSize,
                tripName: config.tripName,
                progress: progress
            )
            if let buffer = pixelBuffer(from: image, size: reelSize) {
                while !writerInput.isReadyForMoreMediaData {
                    try? await Task.sleep(nanoseconds: 10_000_000)
                }
                let time = CMTime(value: frameCount, timescale: fps)
                adaptor.append(buffer, withPresentationTime: time)
                frameCount += 1
            }
        }

        // 2. CLIPS — extract frames from video
        let asset = AVURLAsset(url: config.videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = reelSize
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)

        for clip in config.clips {
            let clipFrameCount = Int(clip.duration * Double(fps))
            for i in 0..<clipFrameCount {
                let time = clip.startTime + Double(i) / Double(fps)
                let cmTime = CMTime(seconds: time, preferredTimescale: 600)

                if let cgImage = try? await generator.image(at: cmTime).image {
                    let uiImage = UIImage(cgImage: cgImage)
                    let fitted = fitImageToReel(uiImage, reelSize: reelSize)
                    if let buffer = pixelBuffer(from: fitted, size: reelSize) {
                        while !writerInput.isReadyForMoreMediaData {
                            try? await Task.sleep(nanoseconds: 10_000_000)
                        }
                        let presentationTime = CMTime(value: frameCount, timescale: fps)
                        adaptor.append(buffer, withPresentationTime: presentationTime)
                        frameCount += 1
                    }
                }
            }
        }

        // 3. SUMMARY — 5 seconds (150 frames)
        let summaryFrames = 150
        for i in 0..<summaryFrames {
            let progress = Float(i) / Float(summaryFrames)
            let image = renderSummaryFrame(
                size: reelSize,
                config: config,
                progress: progress
            )
            if let buffer = pixelBuffer(from: image, size: reelSize) {
                while !writerInput.isReadyForMoreMediaData {
                    try? await Task.sleep(nanoseconds: 10_000_000)
                }
                let time = CMTime(value: frameCount, timescale: fps)
                adaptor.append(buffer, withPresentationTime: time)
                frameCount += 1
            }
        }

        writerInput.markAsFinished()
        await writer.finishWriting()

        return writer.status == .completed ? outputURL : nil
    }

    // MARK: - Intro Frame

    private static func renderIntroFrame(size: CGSize, tripName: String, progress: Float) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Black background
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // KINETIC logo — fade in
            let alpha = CGFloat(min(progress * 3, 1.0))
            let logoAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.08, weight: .black),
                .foregroundColor: UIColor(red: 0.988, green: 0.322, blue: 0, alpha: alpha),
            ]
            let logoStr = NSAttributedString(string: "KINETIC", attributes: logoAttrs)
            let logoSize = logoStr.size()
            logoStr.draw(at: CGPoint(
                x: (size.width - logoSize.width) / 2,
                y: size.height * 0.4 - logoSize.height / 2
            ))

            // Trip name — fade in slightly later
            let nameAlpha = CGFloat(max(0, min((progress - 0.3) * 3, 1.0)))
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.045, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(nameAlpha),
            ]
            let nameStr = NSAttributedString(string: tripName.uppercased(), attributes: nameAttrs)
            let nameSize = nameStr.size()
            nameStr.draw(at: CGPoint(
                x: (size.width - nameSize.width) / 2,
                y: size.height * 0.5
            ))
        }
    }

    // MARK: - Summary Frame

    private static func renderSummaryFrame(size: CGSize, config: ReelConfig, progress: Float) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Dark background
            UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let padding = size.width * 0.08
            let alpha = CGFloat(min(progress * 4, 1.0))

            // Map snapshot in upper area
            if let map = config.mapSnapshot {
                let mapRect = CGRect(x: padding, y: size.height * 0.08, width: size.width - padding * 2, height: size.height * 0.35)
                let mapImage = map.cgImage!
                ctx.cgContext.saveGState()

                let path = UIBezierPath(roundedRect: mapRect, cornerRadius: 20)
                path.addClip()
                ctx.cgContext.draw(mapImage, in: mapRect)

                ctx.cgContext.restoreGState()
            } else if !config.routePoints.isEmpty {
                // Draw route silhouette
                let routeRect = CGRect(x: padding, y: size.height * 0.12, width: size.width - padding * 2, height: size.height * 0.28)
                let path = UIBezierPath()
                for (i, point) in config.routePoints.enumerated() {
                    let x = routeRect.origin.x + point.x * routeRect.width
                    let y = routeRect.origin.y + point.y * routeRect.height
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                UIColor(red: 0.988, green: 0.322, blue: 0, alpha: Double(alpha)).setStroke()
                path.lineWidth = 4
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.stroke()
            }

            // Stats — staggered fade in
            let stats: [(String, String, String)] = [
                ("TIME", config.time, ""),
                ("DISTANCE", config.distance, "km"),
                ("AVG SPEED", config.avgSpeed, "km/h"),
                ("MAX SPEED", config.maxSpeed, "km/h"),
            ]

            let startY = size.height * 0.52
            let statHeight = size.height * 0.09

            for (i, stat) in stats.enumerated() {
                let statAlpha = CGFloat(max(0, min((progress - Float(i) * 0.1) * 5, 1.0)))
                let y = startY + CGFloat(i) * statHeight

                // Label
                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: size.width * 0.032, weight: .medium),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.5 * statAlpha),
                ]
                NSAttributedString(string: stat.0, attributes: labelAttrs)
                    .draw(at: CGPoint(x: padding, y: y))

                // Value
                let valueStr = stat.2.isEmpty ? stat.1 : "\(stat.1) \(stat.2)"
                let valueAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: size.width * 0.07, weight: .bold),
                    .foregroundColor: UIColor.white.withAlphaComponent(statAlpha),
                ]
                NSAttributedString(string: valueStr, attributes: valueAttrs)
                    .draw(at: CGPoint(x: padding, y: y + size.width * 0.035))
            }

            // KINETIC branding at bottom
            let brandAlpha = CGFloat(max(0, min((progress - 0.5) * 3, 1.0)))
            let brandAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.04, weight: .black),
                .foregroundColor: UIColor(red: 0.988, green: 0.322, blue: 0, alpha: brandAlpha),
            ]
            let brandStr = NSAttributedString(string: "KINETIC", attributes: brandAttrs)
            let brandSize = brandStr.size()
            brandStr.draw(at: CGPoint(
                x: (size.width - brandSize.width) / 2,
                y: size.height * 0.92
            ))
        }
    }

    // MARK: - Helpers

    private static func fitImageToReel(_ image: UIImage, reelSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: reelSize)
        return renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: reelSize))

            let imageAspect = image.size.width / image.size.height
            let reelAspect = reelSize.width / reelSize.height

            let drawRect: CGRect
            if imageAspect > reelAspect {
                // Image is wider — fit height, crop sides
                let h = reelSize.height
                let w = h * imageAspect
                drawRect = CGRect(x: (reelSize.width - w) / 2, y: 0, width: w, height: h)
            } else {
                // Image is taller — fit width, center vertically
                let w = reelSize.width
                let h = w / imageAspect
                drawRect = CGRect(x: 0, y: (reelSize.height - h) / 2, width: w, height: h)
            }

            image.draw(in: drawRect)
        }
    }

    private static func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )

        if let cgContext = context, let cgImage = image.cgImage {
            cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
        }

        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
