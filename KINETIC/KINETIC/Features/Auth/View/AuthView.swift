import SwiftUI

struct AuthView: View {
    let coordinator: AppCoordinator

    var body: some View {
        ZStack {
            // Background image
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Dark overlay for readability
            Color.white.opacity(0.10)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text("KINETIC")
                    .font(.inter(24, weight: .black))
                    .foregroundStyle(Color(hex: 0xA73400))

                Text("Ready to\ndrive?")
                    .font(.inter(40, weight: .bold))
                    .foregroundStyle(Color(hex: 0x1A1C1E))
                    .padding(.top, 12)

                Text("Join the Kinetic community.")
                    .font(.inter(16, weight: .regular))
                    .foregroundStyle(Color(hex: 0x5F5E5E))
                    .padding(.top, 8)

                Spacer()

                // Apple button
                Button {
                    coordinator.showMain()
                } label: {
                    HStack(spacing: 12) {
                        Image("apple")
                            .renderingMode(.template)
                        Text("Continue with Apple")
                            .font(.inter(16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Google button
                Button {
                    coordinator.showMain()
                } label: {
                    HStack(spacing: 12) {
                        Image("google")
                        Text("Continue with Google")
                            .font(.inter(16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.4), lineWidth: 1)
                    )
                }
                .padding(.top, 12)

                Spacer()

                // Terms
                VStack(alignment: .leading, spacing: 2) {
                    Text("BY CONTINUING, YOU AGREE TO OUR")
                        .font(.inter(10, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(Color(hex: 0x5F5E5E))

                    HStack(spacing: 4) {
                        Button("TERMS OF SERVICE") {}
                            .font(.inter(10, weight: .medium))
                            .foregroundStyle(Color(hex: 0xA73400))
                        Text("AND")
                            .font(.inter(10, weight: .medium))
                            .foregroundStyle(Color(hex: 0x5F5E5E))
                        Button("PRIVACY POLICY") {}
                            .font(.inter(10, weight: .medium))
                            .foregroundStyle(Color(hex: 0xA73400))
                        Text(".")
                            .font(.inter(10, weight: .medium))
                            .foregroundStyle(Color(hex: 0x5F5E5E))
                    }
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    AuthView(coordinator: AppCoordinator())
}
