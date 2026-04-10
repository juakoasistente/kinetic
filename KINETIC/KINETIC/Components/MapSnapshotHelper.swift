import MapKit
import SwiftUI

struct MapSnapshotHelper {

    /// Generate a map snapshot image with the route polyline drawn on it
    static func generateSnapshot(
        coordinates: [CLLocationCoordinate2D],
        size: CGSize = CGSize(width: 1170, height: 900),  // 3x of 390x300
        lineColor: UIColor = UIColor(Color.stravaOrange),
        lineWidth: CGFloat = 4
    ) async -> UIImage? {
        guard coordinates.count >= 2 else { return nil }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        let region = regionForPolyline(polyline, padding: 1.4)

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.mapType = .standard
        options.showsBuildings = false
        options.pointOfInterestFilter = .excludingAll

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            return drawRoute(on: snapshot, coordinates: coordinates, lineColor: lineColor, lineWidth: lineWidth)
        } catch {
            debugPrint("[MapSnapshot] Failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Normalize coordinates to 0...1 CGPoints for the route silhouette
    static func normalizeCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> [CGPoint] {
        guard coordinates.count >= 2 else { return [] }

        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!

        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon
        guard latRange > 0 || lonRange > 0 else { return [] }

        // Use max range to keep aspect ratio
        let range = max(latRange, lonRange)
        let latOffset = (range - latRange) / 2
        let lonOffset = (range - lonRange) / 2

        return coordinates.map { coord in
            let x = lonRange > 0 ? (coord.longitude - minLon + lonOffset) / range : 0.5
            let y = latRange > 0 ? 1.0 - (coord.latitude - minLat + latOffset) / range : 0.5
            return CGPoint(x: x, y: y)
        }
    }

    // MARK: - Private

    private static func regionForPolyline(_ polyline: MKPolyline, padding: Double) -> MKCoordinateRegion {
        let rect = polyline.boundingMapRect
        let paddedRect = rect.insetBy(dx: -rect.size.width * (padding - 1) / 2,
                                       dy: -rect.size.height * (padding - 1) / 2)
        return MKCoordinateRegion(paddedRect)
    }

    private static func drawRoute(
        on snapshot: MKMapSnapshotter.Snapshot,
        coordinates: [CLLocationCoordinate2D],
        lineColor: UIColor,
        lineWidth: CGFloat
    ) -> UIImage {
        let image = snapshot.image

        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        image.draw(at: .zero)

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return image
        }

        context.setStrokeColor(lineColor.cgColor)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        for (index, coordinate) in coordinates.enumerated() {
            let point = snapshot.point(for: coordinate)
            if index == 0 {
                context.move(to: point)
            } else {
                context.addLine(to: point)
            }
        }

        context.strokePath()

        let result = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        // Crop bottom to remove Apple Maps legal text
        return cropBottom(result, pixels: 30)
    }

    private static func cropBottom(_ image: UIImage, pixels: CGFloat) -> UIImage {
        let scale = image.scale
        let cropHeight = pixels * scale
        let cropRect = CGRect(
            x: 0,
            y: 0,
            width: image.size.width * scale,
            height: (image.size.height * scale) - cropHeight
        )
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
    }
}
