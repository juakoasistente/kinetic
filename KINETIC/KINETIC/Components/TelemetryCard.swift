import SwiftUI

struct TelemetryCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.inter(10, weight: .bold))
                .tracking(1)
                .foregroundStyle(.gravel)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.inter(28, weight: .bold))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.inter(14, weight: .medium))
                    .foregroundStyle(.gravel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.coal.ignoresSafeArea()
        TelemetryCard(title: "DISTANCIA", value: "48.2", unit: "KM")
            .padding()
    }
}
