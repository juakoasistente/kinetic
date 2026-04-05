import SwiftUI
import AudioToolbox

struct CountdownView: View {
    @State private var count = 3
    @State private var showGo = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @Environment(\.dismiss) private var dismiss

    var onComplete: () -> Void = {}

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Glow behind number
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.stravaOrange.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .opacity(opacity)

            // Number or GO
            Text(showGo ? "GO!" : "\(count)")
                .font(.inter(showGo ? 80 : 120, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: .stravaOrange.opacity(0.6), radius: 30)
                .shadow(color: .white.opacity(0.3), radius: 10)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .navigationBarHidden(true)
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {
        SoundPlayer.shared.play("count", extension: "mp3")
        HapticManager.impact(.heavy)
        animateIn()

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            withAnimation(.easeIn(duration: 0.2)) {
                scale = 1.3
                opacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if count > 1 {
                    count -= 1
                    HapticManager.impact(.heavy)
                    animateIn()
                } else if !showGo {
                    showGo = true
                    HapticManager.notification(.success)
                    // System sound: begin recording tone
                    AudioServicesPlaySystemSound(1113)
                    animateIn()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        timer.invalidate()
                        onComplete()
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    private func animateIn() {
        scale = 0.5
        opacity = 0
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1
        }
    }
}

#Preview {
    CountdownView()
}
