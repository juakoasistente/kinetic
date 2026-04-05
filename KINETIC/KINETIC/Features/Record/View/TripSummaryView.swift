import SwiftUI
import MapKit

struct TripSummaryView: View {
    @State private var tripName = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("KINETIC")
                .font(.inter(16, weight: .black))
                .foregroundStyle(.stravaOrange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.black)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Map placeholder
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(Color(hex: 0x2A2A2E))
                            .frame(height: 220)
                            .overlay {
                                Image(systemName: "map")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gravel.opacity(0.3))
                            }

                        // Trip info overlay
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TRIP COMPLETE")
                                .font(.inter(10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.stravaOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Text("TRANS-PYRENEES\nPASS")
                                .font(.inter(28, weight: .black))
                                .foregroundStyle(.white)

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image("calendar")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                    Text("OCT 24, 2023")
                                        .font(.inter(11, weight: .medium))
                                }
                                HStack(spacing: 4) {
                                    Image("ubi")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                    Text("SPAIN / FRANCE")
                                        .font(.inter(11, weight: .medium))
                                }
                            }
                            .foregroundStyle(.gravel)
                        }
                        .padding(20)
                    }

                    // Main stats grid
                    VStack(spacing: 1) {
                        HStack(spacing: 1) {
                            mainStatCard(
                                label: "MAX SPEED",
                                value: "184",
                                unit: "KM/H",
                                labelColor: .stravaOrange
                            )
                            mainStatCard(
                                label: "DISTANCE",
                                value: "14.2",
                                unit: "KM"
                            )
                        }

                        HStack(spacing: 1) {
                            mainStatCard(
                                label: "AVG SPEED",
                                value: "84",
                                unit: "KM/H"
                            )
                            mainStatCard(
                                label: "TIME",
                                value: "00:12:45",
                                unit: ""
                            )
                        }
                    }
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Share button
                    Button {} label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                            Text("SHARE ACTIVITY")
                                .font(.inter(15, weight: .black))
                                .tracking(1)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.stravaOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)

                    // Trip name input
                    TextField("", text: $tripName, prompt: Text("Nombre del viaje (ej: Ruta por la sierra)").foregroundStyle(.gravel))
                        .font(.inter(14, weight: .regular))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    // Save button
                    Button {
                        HapticManager.notification(.success)
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14, weight: .bold))
                            Text("SAVE TO HISTORY")
                                .font(.inter(14, weight: .black))
                                .tracking(1)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(.black)
    }

    // MARK: - Main Stat Card

    private func mainStatCard(
        label: String,
        value: String,
        unit: String,
        labelColor: Color = .gravel
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.inter(10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(labelColor)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.inter(32, weight: .bold))
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
    TripSummaryView()
}
