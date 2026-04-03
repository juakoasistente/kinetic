import SwiftUI

struct PlayerView: View {
    let sessionId: String
    @State private var viewModel: PlayerViewModel

    init(sessionId: String) {
        self.sessionId = sessionId
        self._viewModel = State(initialValue: PlayerViewModel(sessionId: sessionId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Video player placeholder
                ZStack {
                    Rectangle()
                        .fill(.black)
                        .aspectRatio(16/9, contentMode: .fit)

                    Text("Video Player")
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Session info
                VStack(alignment: .leading, spacing: 16) {
                    Text("Session Details")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Telemetry grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        TelemetryCard(title: "DISTANCE", value: "-- km")
                        TelemetryCard(title: "ELEVATION", value: "-- m")
                        TelemetryCard(title: "MAX ALT.", value: "-- m")
                        TelemetryCard(title: "CONSUMPTION", value: "-- L")
                    }
                }
                .padding(24)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("Player")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSession()
        }
    }
}

#Preview {
    NavigationStack {
        PlayerView(sessionId: "preview-1")
    }
}
