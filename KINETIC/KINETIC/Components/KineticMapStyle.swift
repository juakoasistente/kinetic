import SwiftUI
import MapKit

/// Centralized map style for the entire app.
/// Change here to update all maps at once.
enum KineticMapStyle {

    /// Map style used in route displays (TripSummary, Player, Share cards)
    static var route: MapStyle {
        .standard(
            elevation: .flat,
            emphasis: .automatic,
            pointsOfInterest: .excludingAll,
            showsTraffic: false
        )
    }

    /// Route line color
    static var routeColor: Color { .stravaOrange }

    /// Route line width
    static var routeLineWidth: CGFloat { 4 }
}

// MARK: - Preview

#Preview("Map Style") {
    Map(initialPosition: .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.389, longitude: 2.174),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    ))) {
        MapPolyline(coordinates: [
            CLLocationCoordinate2D(latitude: 41.385, longitude: 2.173),
            CLLocationCoordinate2D(latitude: 41.387, longitude: 2.176),
            CLLocationCoordinate2D(latitude: 41.390, longitude: 2.174),
            CLLocationCoordinate2D(latitude: 41.392, longitude: 2.172),
        ])
        .stroke(KineticMapStyle.routeColor, lineWidth: KineticMapStyle.routeLineWidth)
    }
    .mapStyle(KineticMapStyle.route)
    .mapControlVisibility(.hidden)
    .frame(height: 300)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .padding()
}
