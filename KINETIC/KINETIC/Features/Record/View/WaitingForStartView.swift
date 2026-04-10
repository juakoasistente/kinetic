import SwiftUI
import MapKit
import CoreLocation

struct WaitingForStartView: View {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    @Binding var path: [RecordRoute]
    @State private var locationManager = LocationManager()
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @Environment(\.dismiss) private var dismiss

    private var distanceToStart: Double {
        locationManager.distanceToStart ?? 1000
    }

    private var formattedDistance: String {
        if distanceToStart >= 1000 {
            return String(format: "%.1f", distanceToStart / 1000.0)
        }
        return "\(Int(distanceToStart))"
    }

    private var distanceUnit: String {
        distanceToStart >= 1000 ? "km" : "m"
    }

    private var progressToStart: Double {
        let maxDist = 1000.0
        return max(0, min(1, 1 - (distanceToStart / maxDist)))
    }

    var body: some View {
        ZStack {
            // Background image with gradient vignette
            GeometryReader { geo in
                Image("waiting")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            // Full height dark gradient overlay
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.85), location: 0),
                    .init(color: .black.opacity(0.5), location: 0.3),
                    .init(color: .black.opacity(0.3), location: 0.5),
                    .init(color: .black.opacity(0.5), location: 0.7),
                    .init(color: .black.opacity(0.9), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Top label
                Text("ESPERANDO INICIO")
                    .font(.inter(11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.gravel)

                // Speed icon with glow
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.stravaOrange.opacity(glowOpacity))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(.stravaOrange)
                        .frame(width: 72, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.stravaOrange.opacity(0.5), lineWidth: 2)
                        )
                        .overlay {
                            Image("speed")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(pulseScale)
                }
                .padding(.top, 16)

                // Title
                VStack(spacing: 0) {
                    Text("WAITING FOR")
                        .font(.inter(32, weight: .black))
                        .foregroundStyle(.white)
                    Text("START POINT...")
                        .font(.inter(32, weight: .black))
                        .foregroundStyle(.stravaOrange)
                }
                .padding(.top, 16)

                // Proximity card
                HStack(alignment: .firstTextBaseline) {
                    Text(formattedDistance)
                        .font(.inter(48, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(distanceUnit)
                        .font(.inter(20, weight: .bold))
                        .foregroundStyle(.gravel)

                    Spacer()

                    Image(systemName: "location.north.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.stravaOrange)
                        .rotationEffect(.degrees(45))
                }
                .padding(20)
                .background(Color(hex: 0x18181B))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Cancel button
                Button {
                    HapticManager.impact(.light)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("CANCEL")
                            .font(.inter(15, weight: .black))
                            .tracking(1)
                    }
                    .foregroundStyle(.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(hex: 0x18181B))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .onAppear {
            locationManager.requestPermission()
            locationManager.startWaypoint = startCoordinate
            locationManager.endWaypoint = endCoordinate
            locationManager.onReachedStart = {
                HapticManager.notification(.success)
                path.append(.scheduledRecording(endCoordinate: endCoordinate))
            }
            locationManager.startMonitoring()

        }
        .onDisappear {
            locationManager.stopMonitoring()
        }
    }
}

#Preview {
    NavigationStack {
        WaitingForStartView(
            startCoordinate: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
            endCoordinate: CLLocationCoordinate2D(latitude: 40.4530, longitude: -3.6883),
            path: .constant([])
        )
    }
}
