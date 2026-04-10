import SwiftUI
import MapKit

// MARK: - Share Template Enum

enum ShareTemplate: String, CaseIterable, Identifiable {
    case mapStory    // Template 1: Full-bleed map + gradient + stats
    case mapCard     // Template 2: Clean square card with map + stats
    case transparent // Template 3: Transparent bg, route silhouette + stats

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mapStory: "Story"
        case .mapCard: "Card"
        case .transparent: "Transparent"
        }
    }
}

// MARK: - Share Data

struct ShareData {
    let tripName: String
    let date: String
    let maxSpeed: String
    let avgSpeed: String
    let distance: String
    let time: String
    let mapSnapshot: UIImage?
    let routePoints: [CGPoint] // Normalized 0...1 route points for silhouette

    static let preview = ShareData(
        tripName: "Sierra Route",
        date: "APR 07, 2026",
        maxSpeed: "142",
        avgSpeed: "84",
        distance: "48.2",
        time: "48:47",
        mapSnapshot: nil,
        routePoints: [
            CGPoint(x: 0.1, y: 0.5), CGPoint(x: 0.2, y: 0.3),
            CGPoint(x: 0.35, y: 0.2), CGPoint(x: 0.5, y: 0.35),
            CGPoint(x: 0.65, y: 0.15), CGPoint(x: 0.8, y: 0.4),
            CGPoint(x: 0.9, y: 0.6), CGPoint(x: 0.75, y: 0.7),
            CGPoint(x: 0.5, y: 0.65), CGPoint(x: 0.3, y: 0.8),
            CGPoint(x: 0.1, y: 0.5),
        ]
    )
}

// MARK: - Template 1: Map Story (9:16 vertical)

struct ShareMapStoryView: View {
    let data: ShareData

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map background
            if let snapshot = data.mapSnapshot {
                Image(uiImage: snapshot)
                    .resizable()
                    .scaledToFill()
            } else {
                // Placeholder gradient when no map
                LinearGradient(
                    colors: [Color(hex: 0xC8D6C5), Color(hex: 0xD4D9D2), Color(hex: 0xB8C4B5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.3), .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Bottom content
            VStack(alignment: .leading, spacing: 16) {
                Spacer()

                // Icon + Logo
                HStack {
                    Image(systemName: "car.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("KINETIC")
                        .font(.inter(16, weight: .black))
                        .foregroundStyle(.white)
                }

                // Trip name
                Text(data.tripName)
                    .font(.inter(24, weight: .bold))
                    .foregroundStyle(.white)

                // Stats
                HStack(spacing: 24) {
                    storyStatItem(label: "Time", value: data.time)
                    storyStatItem(label: "Distance", value: "\(data.distance) km")
                }

                HStack(spacing: 24) {
                    storyStatItem(label: "Avg Speed", value: "\(data.avgSpeed) km/h")
                    storyStatItem(label: "Max Speed", value: "\(data.maxSpeed) km/h")
                }
            }
            .padding(24)
        }
        .frame(width: 390, height: 693) // 9:16 ratio
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func storyStatItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.inter(11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.inter(22, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Template 2: Map Card (square)

struct ShareMapCardView: View {
    let data: ShareData

    var body: some View {
        VStack(spacing: 0) {
            // Map area
            ZStack(alignment: .topTrailing) {
                if let snapshot = data.mapSnapshot {
                    Image(uiImage: snapshot)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                } else {
                    // Placeholder
                    Rectangle()
                        .fill(Color(hex: 0xE8EDE6))
                        .frame(height: 300)
                        .overlay {
                            // Draw route silhouette as placeholder
                            routeShape
                                .stroke(Color.stravaOrange, lineWidth: 3)
                                .padding(40)
                        }
                }

                // Logo
                Text("KINETIC")
                    .font(.inter(14, weight: .black))
                    .foregroundStyle(Color.coal)
                    .padding(12)
            }

            // Stats bar
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    cardStatItem(label: "Time", value: data.time, unit: "")
                    cardStatItem(label: "Distance", value: data.distance, unit: "km")
                }
                HStack(spacing: 0) {
                    cardStatItem(label: "Avg Speed", value: data.avgSpeed, unit: "km/h")
                    cardStatItem(label: "Max Speed", value: data.maxSpeed, unit: "km/h")
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color.white)
        }
        .frame(width: 390)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }

    private func cardStatItem(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.inter(11, weight: .medium))
                .foregroundStyle(Color.gravel)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.inter(20, weight: .bold))
                    .foregroundStyle(Color.coal)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.inter(12, weight: .medium))
                        .foregroundStyle(Color.gravel)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var routeShape: Path {
        Path { path in
            guard let first = data.routePoints.first else { return }
            let size = CGSize(width: 310, height: 220)
            path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
            for point in data.routePoints.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
            }
        }
    }
}

// MARK: - Template 3: Transparent

struct ShareTransparentView: View {
    let data: ShareData

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Stats
            VStack(spacing: 20) {
                transparentStatItem(label: "Time", value: data.time, unit: "")
                transparentStatItem(label: "Distance", value: data.distance, unit: "km")
                transparentStatItem(label: "Avg Speed", value: data.avgSpeed, unit: "km/h")
                transparentStatItem(label: "Max Speed", value: data.maxSpeed, unit: "km/h")
            }

            // Route silhouette
            routeShape
                .stroke(Color.stravaOrange, lineWidth: 3)
                .frame(width: 120, height: 60)
                .padding(.top, 8)

            // Logo
            Text("KINETIC")
                .font(.inter(14, weight: .black))
                .foregroundStyle(.white)
                .padding(.top, 8)

            Spacer()
        }
        .frame(width: 390, height: 693)
        .background(Color.clear)
    }

    private func transparentStatItem(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.inter(13, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.inter(42, weight: .bold))
                    .foregroundStyle(.white)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.inter(16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    private var routeShape: Path {
        Path { path in
            guard let first = data.routePoints.first else { return }
            path.move(to: CGPoint(x: first.x * 120, y: first.y * 60))
            for point in data.routePoints.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * 120, y: point.y * 60))
            }
        }
    }
}

// MARK: - Share Card View (Template Switcher)

struct ShareCardView: View {
    let data: ShareData
    let template: ShareTemplate

    var body: some View {
        switch template {
        case .mapStory:
            ShareMapStoryView(data: data)
        case .mapCard:
            ShareMapCardView(data: data)
        case .transparent:
            ShareTransparentView(data: data)
        }
    }
}

// MARK: - Share Image Generator

@MainActor
func generateShareImage(data: ShareData, template: ShareTemplate) -> UIImage? {
    let view = ShareCardView(data: data, template: template)

    let renderer: ImageRenderer<ShareCardView>
    if template == .transparent {
        // Render with dark background for preview, but transparent for actual export
        renderer = ImageRenderer(content: view)
    } else {
        renderer = ImageRenderer(content: view)
    }
    renderer.scale = 3 // High resolution
    return renderer.uiImage
}

// MARK: - Previews

#Preview("Story") {
    ZStack {
        Color.black.ignoresSafeArea()
        ShareMapStoryView(data: .preview)
            .padding()
    }
}

#Preview("Card") {
    ZStack {
        Color(hex: 0xF0F0F0).ignoresSafeArea()
        ShareMapCardView(data: .preview)
            .padding()
    }
}

#Preview("Transparent") {
    ZStack {
        // Checkerboard to show transparency
        Color(hex: 0x2A2A2A).ignoresSafeArea()
        ShareTransparentView(data: .preview)
            .padding()
    }
}
