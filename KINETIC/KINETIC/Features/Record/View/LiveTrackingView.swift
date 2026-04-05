import SwiftUI
import Combine

struct LiveTrackingView: View {
    @State private var speed: Int = 124
    @State private var maxSpeed: Int = 184
    @State private var avgSpeed: Int = 84
    @State private var distance: Double = 14.2
    @State private var elapsed: TimeInterval = 765 // 00:12:45
    @State private var isPaused = false
    @State private var showSummary = false
    @Environment(\.dismiss) private var dismiss

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Image("logoNavBar")
                .padding(.top, 16)

            // Speed display
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, -20)
                .padding(.top, 24)

                // Big speed
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.15), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 160
                            )
                        )
                        .frame(width: 280, height: 280)
                        .blur(radius: 20)

                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(speed)")
                            .font(.inter(100, weight: .black))
                            .italic()
                            .foregroundStyle(.white)
                        Text(" KM/H")
                            .font(.inter(20, weight: .bold))
                            .foregroundStyle(.stravaOrange)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.top, 36)
            }
            .padding(.horizontal, 20)

            Spacer()

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 1),
                GridItem(.flexible(), spacing: 1)
            ], spacing: 1) {
                statCard(label: "VELOCIDAD MÁX", value: "\(maxSpeed)", unit: "KM/H")
                statCard(label: "VELOCIDAD MEDIA", value: "\(avgSpeed)", unit: "KM/H")
                statCard(label: "DISTANCIA", value: String(format: "%.1f", distance), unit: "KM")
                statCard(label: "TIEMPO", value: formattedTime, unit: "")
            }
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        isPaused.toggle()
                    }
                    HapticManager.impact(.medium)
                } label: {
                    HStack(spacing: 10) {
                        Text(isPaused ? "RESUME TRACKING" : "PAUSE TRACKING")
                            .font(.inter(15, weight: .black))
                            .tracking(1)
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }

                Button {
                    HapticManager.notification(.warning)
                    showSummary = true
                } label: {
                    HStack(spacing: 10) {
                        Text("STOP TRACKING")
                            .font(.inter(15, weight: .black))
                            .tracking(1)
                        Image("stop")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.stravaOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(.black)
        .fullScreenCover(isPresented: $showSummary) {
            TripSummaryView()
        }
        .onReceive(timer) { _ in
            guard !isPaused else { return }
            elapsed += 1
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let h = Int(elapsed) / 3600
        let m = (Int(elapsed) % 3600) / 60
        let s = Int(elapsed) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func statCard(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.inter(10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.gravel)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.inter(28, weight: .bold))
                    .foregroundStyle(.white)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.inter(12, weight: .medium))
                        .foregroundStyle(.gravel)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.05))
    }
}

#Preview {
    LiveTrackingView()
}
