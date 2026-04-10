import SwiftUI

struct SpinningView: View {
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .foregroundStyle(.stravaOrange)
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(outerRotation))

            // Inner ring
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .foregroundStyle(Color.gravel.opacity(0.4))
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(innerRotation))
        }
        .onAppear {
            guard !isAnimating else { return }
            isAnimating = true
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
        }
    }
}

#Preview {
    ZStack {
        Color.fog.ignoresSafeArea()
        SpinningView()
    }
}
