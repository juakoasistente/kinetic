import SwiftUI

struct PlayerView: View {
    let sessionId: String
    @State private var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    init(sessionId: String) {
        self.sessionId = sessionId
        self._viewModel = State(initialValue: PlayerViewModel(sessionId: sessionId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image("back")
                            .renderingMode(.template)
                            .foregroundStyle(.stravaOrange)
                        Text("Reproductor")
                            .font(.inter(16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                Spacer()

                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundStyle(.gravel)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.black)

            ScrollView {
                VStack(spacing: 0) {
                    // Video player area with overlays
                    ZStack(alignment: .bottom) {
                        // Video placeholder
                        Rectangle()
                            .fill(Color.asphalt)
                            .aspectRatio(16 / 10, contentMode: .fit)
                            .overlay {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.3))
                            }

                        // Telemetry overlays
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 8) {
                                // Speed
                                telemetryOverlay {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("VELOCIDAD")
                                            .font(.inter(8, weight: .bold))
                                            .tracking(1)
                                            .foregroundStyle(.white.opacity(0.7))
                                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                                            Text("142")
                                                .font(.inter(32, weight: .black))
                                                .foregroundStyle(.stravaOrange)
                                            Text("KM/H")
                                                .font(.inter(11, weight: .bold))
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                    }
                                }

                                // G-Force
                                telemetryOverlay {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("FUERZA G")
                                            .font(.inter(8, weight: .bold))
                                            .tracking(1)
                                            .foregroundStyle(.white.opacity(0.7))
                                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                                            Text("1.2")
                                                .font(.inter(28, weight: .black))
                                                .foregroundStyle(.white)
                                            Text("G")
                                                .font(.inter(12, weight: .bold))
                                                .foregroundStyle(.white.opacity(0.5))
                                        }
                                    }
                                }
                            }

                            Spacer()

                            // Session time
                            telemetryOverlay {
                                VStack(spacing: 2) {
                                    Text("TIEMPO DE SESIÓN")
                                        .font(.inter(8, weight: .bold))
                                        .tracking(1)
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text("00 : 42 : 15")
                                        .font(.inter(22, weight: .black))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding(12)

                        // Progress bar
                        VStack(spacing: 0) {
                            Spacer()
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(.stravaOrange)
                                        .frame(height: 4)
                                    Rectangle()
                                        .fill(.stravaOrange)
                                        .frame(width: geo.size.width * 0.65, height: 4)
                                    Circle()
                                        .fill(.stravaOrange)
                                        .frame(width: 12, height: 12)
                                        .offset(x: geo.size.width * 0.65 - 6)
                                }
                            }
                            .frame(height: 12)
                        }
                    }

                    // Session info - dark section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paso de Stelvio")
                            .font(.inter(24, weight: .extraBold))
                            .foregroundStyle(.white)

                        Text("Sesión grabada el 14 de Octubre, 2023")
                            .font(.inter(14, weight: .regular))
                            .foregroundStyle(.gravel)

                        // Telemetry grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            TelemetryCard(title: "DISTANCIA", value: "48.2", unit: "KM")
                            TelemetryCard(title: "ELEVACIÓN", value: "1,840", unit: "M")
                            TelemetryCard(title: "PUNTO MÁX.", value: "2,757", unit: "M")
                            TelemetryCard(title: "CONSUMO", value: "14.2", unit: "L")
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)

                }
            }

            // Bottom actions - fixed
            HStack(spacing: 0) {
                actionButton(icon: "arrow.down.to.line", title: "DESCARGAR", color: .gravel) {}

                // Center telemetry button
                Button {} label: {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(.stravaOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .stravaOrange.opacity(0.4), radius: 12, y: 4)
                }

                actionButton(icon: "trash", title: "ELIMINAR", color: .danger) {}
            }
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(.black)
        .navigationBarHidden(true)
        .swipeBack { dismiss() }
        .task {
            await viewModel.loadSession()
        }
    }

    // MARK: - Helpers

    private func telemetryOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(10)
            .background(.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.inter(10, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                PlayerView(sessionId: "preview-1")
            }
    }
}
