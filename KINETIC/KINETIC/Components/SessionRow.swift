import SwiftUI

struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gravel.opacity(0.2))
                .frame(width: 90, height: 90)
                .overlay {
                    if session.hasVideo {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "road.lanes")
                            .font(.system(size: 24))
                            .foregroundStyle(.gravel.opacity(0.5))
                    }
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(session.name)
                        .font(.inter(16, weight: .bold))
                        .foregroundStyle(.coal)

                    Spacer()

                    Text(session.formattedDate)
                        .font(.inter(11, weight: .medium))
                        .foregroundStyle(.gravel)
                }

                Text("\(session.category) \u{2022} \(session.vehicle)")
                    .font(.inter(13, weight: .medium))
                    .foregroundStyle(.stravaOrange)

                Spacer(minLength: 4)

                // Stats
                if session.hasVideo {
                    HStack(spacing: 20) {
                        statItem(label: "TYPE", value: session.videoType ?? "")
                        statItem(label: "LENGTH", value: session.videoLength ?? "")

                        Spacer()

                        Image(systemName: "video")
                            .font(.system(size: 14))
                            .foregroundStyle(.gravel.opacity(0.5))
                    }
                } else {
                    HStack(spacing: 20) {
                        statItem(label: "DIST", value: session.formattedDistance)
                        statItem(label: "TIME", value: session.formattedDuration)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.gravel.opacity(0.4))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.inter(10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.gravel)
            Text(value)
                .font(.inter(15, weight: .bold))
                .foregroundStyle(.coal)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        SessionRow(session: Session.mockData[0])
        Divider()
        SessionRow(session: Session.mockData[2])
    }
}
