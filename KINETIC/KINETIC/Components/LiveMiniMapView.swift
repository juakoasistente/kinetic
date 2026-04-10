import SwiftUI
import CoreLocation

struct LiveMiniMapView: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    // Circular glass background
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 100, height: 100)
                        .opacity(0.85)

                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        .frame(width: 100, height: 100)

                    // Compass grid
                    compassGrid

                    // Route
                    routeCanvas
                        .frame(width: 84, height: 84)
                        .clipShape(Circle())
                }
                .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
                .padding(.trailing, 16)
                .padding(.top, 100)
            }
            Spacer()
        }
    }

    // MARK: - Compass Grid

    private var compassGrid: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2 - 12
            let lineColor = Color.white.opacity(0.06)

            var vLine = Path()
            vLine.move(to: CGPoint(x: center.x, y: center.y - radius))
            vLine.addLine(to: CGPoint(x: center.x, y: center.y + radius))
            context.stroke(vLine, with: .color(lineColor), lineWidth: 0.5)

            var hLine = Path()
            hLine.move(to: CGPoint(x: center.x - radius, y: center.y))
            hLine.addLine(to: CGPoint(x: center.x + radius, y: center.y))
            context.stroke(hLine, with: .color(lineColor), lineWidth: 0.5)

            let innerRadius = radius * 0.5
            let innerRect = CGRect(
                x: center.x - innerRadius, y: center.y - innerRadius,
                width: innerRadius * 2, height: innerRadius * 2
            )
            context.stroke(Path(ellipseIn: innerRect), with: .color(lineColor), lineWidth: 0.5)
        }
        .frame(width: 100, height: 100)
    }

    // MARK: - Route Canvas

    /// Filter out points that are too close together (no real movement)
    private var significantCoordinates: [CLLocationCoordinate2D] {
        guard coordinates.count >= 2 else { return coordinates }
        var filtered: [CLLocationCoordinate2D] = [coordinates[0]]
        for coord in coordinates.dropFirst() {
            let last = filtered.last!
            let latDiff = abs(coord.latitude - last.latitude)
            let lonDiff = abs(coord.longitude - last.longitude)
            // ~5 meters minimum movement
            if latDiff > 0.00005 || lonDiff > 0.00005 {
                filtered.append(coord)
            }
        }
        return filtered
    }

    private var routeCanvas: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // Always show a position dot in the center when no movement
            let coords = significantCoordinates
            guard coords.count >= 2 else {
                // Static dot — waiting or no movement
                let dotRect = CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: dotRect), with: .color(Color.stravaOrange.opacity(0.5)))
                let innerRect = CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4)
                context.fill(Path(ellipseIn: innerRect), with: .color(.white.opacity(0.5)))
                return
            }

            let padding: CGFloat = 12
            let drawArea = CGRect(
                x: padding, y: padding,
                width: size.width - padding * 2,
                height: size.height - padding * 2
            )

            let points = normalizedPoints(in: drawArea)
            guard points.count >= 2 else { return }

            // Route — single solid orange line
            var path = Path()
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            context.stroke(path, with: .color(Color.stravaOrange), lineWidth: 2.5)

            // Current position dot
            if let last = points.last {
                let dotRect = CGRect(x: last.x - 4, y: last.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: dotRect), with: .color(Color.stravaOrange))
                let innerRect = CGRect(x: last.x - 2, y: last.y - 2, width: 4, height: 4)
                context.fill(Path(ellipseIn: innerRect), with: .color(.white))
            }

            // Start point
            if let first = points.first, points.count > 3 {
                let startRect = CGRect(x: first.x - 2.5, y: first.y - 2.5, width: 5, height: 5)
                context.stroke(Path(ellipseIn: startRect), with: .color(.white.opacity(0.3)), lineWidth: 1)
            }
        }
    }

    // MARK: - Normalize

    private func normalizedPoints(in rect: CGRect) -> [CGPoint] {
        let coords = significantCoordinates
        guard coords.count >= 2 else { return [] }

        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!

        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon
        let range = max(latRange, lonRange)

        guard range > 0 else {
            return [CGPoint(x: rect.midX, y: rect.midY)]
        }

        let latOffset = (range - latRange) / 2
        let lonOffset = (range - lonRange) / 2

        return coords.map { coord in
            let x = rect.origin.x + CGFloat((coord.longitude - minLon + lonOffset) / range) * rect.width
            let y = rect.origin.y + CGFloat(1.0 - (coord.latitude - minLat + latOffset) / range) * rect.height
            return CGPoint(x: x, y: y)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: 0x1A1A1A).ignoresSafeArea()
        LiveMiniMapView(coordinates: [
            CLLocationCoordinate2D(latitude: 41.385, longitude: 2.173),
            CLLocationCoordinate2D(latitude: 41.386, longitude: 2.174),
            CLLocationCoordinate2D(latitude: 41.387, longitude: 2.176),
            CLLocationCoordinate2D(latitude: 41.389, longitude: 2.175),
            CLLocationCoordinate2D(latitude: 41.390, longitude: 2.173),
            CLLocationCoordinate2D(latitude: 41.391, longitude: 2.171),
            CLLocationCoordinate2D(latitude: 41.392, longitude: 2.172),
        ])
    }
}
