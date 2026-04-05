import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let badge: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon card
            VStack(spacing: 17) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(Color(hex: 0x6D6D78).opacity(0.5))
                            .overlay(alignment: .center) {
                                Rectangle()
                                    .fill(Color(hex: 0xA73400))
                                    .frame(width: 2, height: 56)
                                    .rotationEffect(.degrees(-45))
                            }
                    }

                // Badge
                Text(badge.uppercased())
                    .font(.inter(10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0x1A1C1E))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Title
            Text(title)
                .font(.inter(28, weight: .extraBold))
                .foregroundStyle(Color(hex: 0x1A1C1E))
                .padding(.top, 20)

            // Subtitle
            Text(subtitle)
                .font(.inter(15, weight: .regular))
                .foregroundStyle(Color(hex: 0x6D6D78))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 26)

            // Button
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 16, weight: .semibold))
                    Text(buttonTitle)
                        .font(.inter(16, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color(hex: 0xFC5200))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 42)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0xF7F7FA))
    }
}

#Preview {
    EmptyStateView(
        icon: "video",
        badge: "No Data",
        title: "No Recordings Yet",
        subtitle: "Record your first drive with telemetry to share it with the community.",
        buttonTitle: "Start Recording",
        action: {}
    )
}
