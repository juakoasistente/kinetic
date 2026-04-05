import SwiftUI

enum RecordMode: String, CaseIterable, Identifiable {
    case gpx
    case liveOverlay
    case dataOnly

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gpx: "square.and.arrow.up.fill"
        case .liveOverlay: "video.fill"
        case .dataOnly: "antenna.radiowaves.left.and.right"
        }
    }

    var title: String {
        switch self {
        case .gpx: "Import GPX Route"
        case .liveOverlay: "RECORD WITH LIVE OVERLAY"
        case .dataOnly: "Start Data-Only Tracking"
        }
    }

    var subtitle: String {
        switch self {
        case .gpx: "Load a pre-defined track or trail"
        case .liveOverlay: "Video capture with real-time telemetry"
        case .dataOnly: "Minimal battery usage, pure GPS logs"
        }
    }

    var isHighlighted: Bool {
        self == .liveOverlay
    }
}

struct RecordView: View {
    @Environment(MainTabCoordinator.self) private var tabCoordinator
    @State private var showTrackingConfig = false
    @State private var trackingPath: [RecordRoute] = []

    private var path: Binding<[RecordRoute]> {
        Binding(
            get: { tabCoordinator.recordPath },
            set: { tabCoordinator.recordPath = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("SELECT MODE")
                    .font(.inter(28, weight: .black))
                    .italic()
                    .foregroundStyle(.stravaOrange)
                    .padding(.top, 24)

                Text("Choose how you want to track your performance session today.")
                    .font(.inter(15, weight: .regular))
                    .foregroundStyle(.gravel)
                    .padding(.top, 8)

                // Mode cards
                VStack(spacing: 14) {
                    ForEach(RecordMode.allCases) { mode in
                        RecordModeCard(mode: mode) {
                            if mode == .dataOnly {
                                showTrackingConfig = true
                            }
                        }
                    }
                }
                .padding(.top, 28)
            }
            .padding(.horizontal, 20)
        }
        .background(.fog)
        .toolbarBackground(.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("logoNavBar")
            }
        }
        .fullScreenCover(isPresented: $showTrackingConfig) {
            trackingPath = []
        } content: {
            NavigationStack(path: $trackingPath) {
                TrackingConfigView(path: $trackingPath)
                    .navigationDestination(for: RecordRoute.self) { route in
                        switch route {
                        case .countdown:
                            CountdownView {
                                trackingPath = [.recording]
                            }
                        case .recording:
                            LiveTrackingView()
                                .navigationBarBackButtonHidden(true)
                        default:
                            EmptyView()
                        }
                    }
            }
        }
    }
}

// MARK: - Mode Card

struct RecordModeCard: View {
    let mode: RecordMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: mode.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(mode.isHighlighted ? .stravaOrange : .stravaOrange)
                    .frame(width: 48, height: 48)
                    .background(mode.isHighlighted ? Color.stravaOrange.opacity(0.15) : .mist)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.inter(15, weight: .bold))
                        .foregroundStyle(mode.isHighlighted ? .stravaOrange : .coal)
                    Text(mode.subtitle)
                        .font(.inter(13, weight: .regular))
                        .foregroundStyle(mode.isHighlighted ? .stravaOrange.opacity(0.7) : .gravel)
                        .lineLimit(2)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(mode.isHighlighted ? .stravaOrange : .gravel.opacity(0.4))
            }
            .padding(16)
            .background(mode.isHighlighted ? Color.stravaOrange.opacity(0.08) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(mode.isHighlighted ? Color.stravaOrange.opacity(0.2) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        RecordView()
    }
    .environment(MainTabCoordinator())
}
