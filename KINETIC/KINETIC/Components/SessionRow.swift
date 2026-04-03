import SwiftUI

struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 80)
                .overlay {
                    if session.hasVideo {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.headline)

                Text("\(session.category) \u{2022} \(session.vehicle)")
                    .font(.subheadline)
                    .foregroundStyle(.orange)

                HStack(spacing: 16) {
                    Label("\(String(format: "%.1f", session.distance)) km", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    Label(session.duration.formatted(), systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
