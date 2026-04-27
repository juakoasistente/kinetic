import UIKit
import CoreGraphics

/// Renders telemetry data as an overlay image to composite onto video frames.
final class OverlayRenderer {
    
    // MARK: - Configuration
    
    struct OverlayConfig {
        var showSpeed: Bool = true
        var showDistance: Bool = true
        var showTime: Bool = true
        var showAltitude: Bool = true
        var showMaxSpeed: Bool = false
        var showElevationGain: Bool = false
        var showHeading: Bool = false
        var useMetric: Bool = true // km/h vs mph
        var position: OverlayPosition = .bottomLeft
        var style: OverlayStyle = .modern
        var opacity: CGFloat = 0.9
        var scale: CGFloat = 1.0
    }
    
    enum OverlayPosition {
        case topLeft, topRight, bottomLeft, bottomRight, center
    }
    
    enum OverlayStyle {
        case modern     // Clean, rounded cards
        case minimal    // Just text, no background
        case racing     // Bold, high contrast
        case classic    // Retro speedometer feel
    }
    
    // MARK: - Render
    
    /// Render an overlay image for the given telemetry data at a specific video frame size.
    static func renderOverlay(
        data: GPXParser.InterpolatedData,
        videoSize: CGSize,
        config: OverlayConfig
    ) -> UIImage? {
        
        let renderer = UIGraphicsImageRenderer(size: videoSize)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Calculate overlay area
            let padding: CGFloat = 20 * config.scale
            let cardWidth: CGFloat = 200 * config.scale
            let lineHeight: CGFloat = 32 * config.scale
            
            var items: [(label: String, value: String, unit: String)] = []
            
            if config.showSpeed {
                let speed = config.useMetric ? data.speed : data.speed * 0.621371
                let unit = config.useMetric ? "km/h" : "mph"
                items.append(("SPEED", String(format: "%.0f", speed), unit))
            }
            
            if config.showDistance {
                let dist = config.useMetric ? data.distance : data.distance * 0.621371
                let unit = config.useMetric ? (data.distance < 1 ? "m" : "km") : "mi"
                let value = data.distance < 1 ? String(format: "%.0f", dist * 1000) : String(format: "%.2f", dist)
                items.append(("DIST", value, unit))
            }
            
            if config.showTime {
                let h = Int(data.elapsed) / 3600
                let m = (Int(data.elapsed) % 3600) / 60
                let s = Int(data.elapsed) % 60
                let time = h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
                items.append(("TIME", time, ""))
            }
            
            if config.showAltitude {
                let alt = config.useMetric ? data.altitude : data.altitude * 3.281
                let unit = config.useMetric ? "m" : "ft"
                items.append(("ALT", String(format: "%.0f", alt), unit))
            }
            
            if config.showElevationGain {
                let gain = config.useMetric ? data.elevationGain : data.elevationGain * 3.281
                let unit = config.useMetric ? "m" : "ft"
                items.append(("ELEV ↑", String(format: "%.0f", gain), unit))
            }
            
            guard !items.isEmpty else { return }
            
            let totalHeight = CGFloat(items.count) * lineHeight + padding * 2
            
            // Position
            var originX: CGFloat = padding
            var originY: CGFloat = videoSize.height - totalHeight - padding
            
            switch config.position {
            case .topLeft:
                originX = padding
                originY = padding + 60 * config.scale // Below safe area
            case .topRight:
                originX = videoSize.width - cardWidth - padding
                originY = padding + 60 * config.scale
            case .bottomLeft:
                originX = padding
                originY = videoSize.height - totalHeight - padding
            case .bottomRight:
                originX = videoSize.width - cardWidth - padding
                originY = videoSize.height - totalHeight - padding
            case .center:
                originX = (videoSize.width - cardWidth) / 2
                originY = (videoSize.height - totalHeight) / 2
            }
            
            switch config.style {
            case .modern:
                renderModern(ctx: ctx, items: items, origin: CGPoint(x: originX, y: originY),
                           cardWidth: cardWidth, lineHeight: lineHeight, padding: padding, config: config)
            case .minimal:
                renderMinimal(ctx: ctx, items: items, origin: CGPoint(x: originX, y: originY),
                            lineHeight: lineHeight, config: config)
            case .racing:
                renderRacing(ctx: ctx, items: items, origin: CGPoint(x: originX, y: originY),
                           cardWidth: cardWidth, lineHeight: lineHeight, padding: padding, config: config)
            case .classic:
                renderModern(ctx: ctx, items: items, origin: CGPoint(x: originX, y: originY),
                           cardWidth: cardWidth, lineHeight: lineHeight, padding: padding, config: config)
            }
        }
    }
    
    // MARK: - Style Renderers
    
    private static func renderModern(
        ctx: CGContext, items: [(label: String, value: String, unit: String)],
        origin: CGPoint, cardWidth: CGFloat, lineHeight: CGFloat, padding: CGFloat, config: OverlayConfig
    ) {
        let totalHeight = CGFloat(items.count) * lineHeight + padding * 2
        let rect = CGRect(x: origin.x, y: origin.y, width: cardWidth, height: totalHeight)
        
        // Background card with rounded corners
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 12 * config.scale)
        UIColor.black.withAlphaComponent(0.6 * config.opacity).setFill()
        path.fill()
        
        // Items
        for (index, item) in items.enumerated() {
            let y = origin.y + padding + CGFloat(index) * lineHeight
            
            // Label
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10 * config.scale, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            let labelStr = NSString(string: item.label)
            labelStr.draw(at: CGPoint(x: origin.x + padding, y: y), withAttributes: labelAttrs)
            
            // Value
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 20 * config.scale, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let valueStr = NSString(string: item.value)
            let valueSize = valueStr.size(withAttributes: valueAttrs)
            valueStr.draw(at: CGPoint(x: origin.x + cardWidth - padding - valueSize.width - 30 * config.scale, y: y - 2), withAttributes: valueAttrs)
            
            // Unit
            if !item.unit.isEmpty {
                let unitAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10 * config.scale, weight: .regular),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.5)
                ]
                let unitStr = NSString(string: item.unit)
                unitStr.draw(at: CGPoint(x: origin.x + cardWidth - padding - 25 * config.scale, y: y + 4), withAttributes: unitAttrs)
            }
        }
    }
    
    private static func renderMinimal(
        ctx: CGContext, items: [(label: String, value: String, unit: String)],
        origin: CGPoint, lineHeight: CGFloat, config: OverlayConfig
    ) {
        for (index, item) in items.enumerated() {
            let y = origin.y + CGFloat(index) * lineHeight
            
            let text = item.unit.isEmpty ? item.value : "\(item.value) \(item.unit)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 18 * config.scale, weight: .bold),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -3.0 // Negative = fill + stroke
            ]
            let str = NSString(string: text)
            str.draw(at: CGPoint(x: origin.x, y: y), withAttributes: attrs)
        }
    }
    
    private static func renderRacing(
        ctx: CGContext, items: [(label: String, value: String, unit: String)],
        origin: CGPoint, cardWidth: CGFloat, lineHeight: CGFloat, padding: CGFloat, config: OverlayConfig
    ) {
        let totalHeight = CGFloat(items.count) * lineHeight + padding * 2
        let rect = CGRect(x: origin.x, y: origin.y, width: cardWidth, height: totalHeight)
        
        // Red accent background
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 4 * config.scale)
        UIColor.black.withAlphaComponent(0.8 * config.opacity).setFill()
        path.fill()
        
        // Red left border
        let borderRect = CGRect(x: origin.x, y: origin.y, width: 4 * config.scale, height: totalHeight)
        let borderPath = UIBezierPath(rect: borderRect)
        UIColor(red: 1, green: 0.2, blue: 0.1, alpha: 1).setFill()
        borderPath.fill()
        
        for (index, item) in items.enumerated() {
            let y = origin.y + padding + CGFloat(index) * lineHeight
            
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 22 * config.scale, weight: .black),
                .foregroundColor: UIColor.white
            ]
            let text = item.unit.isEmpty ? "\(item.label) \(item.value)" : "\(item.value) \(item.unit)"
            let str = NSString(string: text)
            str.draw(at: CGPoint(x: origin.x + padding + 4 * config.scale, y: y - 2), withAttributes: valueAttrs)
        }
    }
}
