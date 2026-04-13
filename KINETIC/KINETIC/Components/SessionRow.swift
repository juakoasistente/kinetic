import SwiftUI

struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Thumbnail
            sessionThumbnail

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

                if !session.category.isEmpty || !session.vehicle.isEmpty {
                    let detail = [session.category, session.vehicle]
                        .filter { !$0.isEmpty }
                        .joined(separator: " \u{2022} ")
                    Text(detail)
                        .font(.inter(13, weight: .medium))
                        .foregroundStyle(.stravaOrange)
                }

                if let location = session.locationName, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 9))
                        Text(location)
                            .font(.inter(11, weight: .regular))
                    }
                    .foregroundStyle(.gravel)
                }

                Spacer(minLength: 4)

                // Stats
                HStack(spacing: 20) {
                    statItem(label: "DIST", value: session.formattedDistance)
                    statItem(label: "TIME", value: session.formattedDuration)

                    Spacer()

                    if session.hasVideo {
                        Image(systemName: "video.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.stravaOrange.opacity(0.6))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.gravel.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Thumbnail

    private var sessionThumbnail: some View {
        Group {
            if let thumbnailUrl = session.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                // Real thumbnail from Supabase
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    thumbnailPlaceholder
                }
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                // Placeholder based on session type
                thumbnailPlaceholder
            }
        }
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(session.hasVideo
                  ? Color.coal
                  : Color.stravaOrange.opacity(0.1))
            .frame(width: 90, height: 90)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: session.hasVideo ? "video.fill" : "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(session.hasVideo ? .white.opacity(0.6) : .stravaOrange.opacity(0.5))

                    Text(session.formattedDistance)
                        .font(.inter(10, weight: .bold))
                        .foregroundStyle(session.hasVideo ? .white.opacity(0.4) : .stravaOrange.opacity(0.4))
                }
            }
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
    VStack(spacing: 12) {
        SessionRow(session: Session.mockData[0])
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        SessionRow(session: Session.mockData[2])
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    .padding()
    .background(Color.fog)
}
