import SwiftUI
import CoreLocation
import UniformTypeIdentifiers

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
        case .gpx: LanguageManager.shared.localizedString("record.gpx.title")
        case .liveOverlay: LanguageManager.shared.localizedString("record.liveOverlay.title")
        case .dataOnly: LanguageManager.shared.localizedString("record.dataOnly.title")
        }
    }

    var subtitle: String {
        switch self {
        case .gpx: LanguageManager.shared.localizedString("record.gpx.subtitle")
        case .liveOverlay: LanguageManager.shared.localizedString("record.liveOverlay.subtitle")
        case .dataOnly: LanguageManager.shared.localizedString("record.dataOnly.subtitle")
        }
    }

    var isHighlighted: Bool {
        self == .liveOverlay
    }

    var isLocked: Bool {
        false
    }
}

struct RecordView: View {
    @Environment(MainTabCoordinator.self) private var tabCoordinator
    @State private var showTrackingConfig = false
    @State private var showLiveOverlay = false
    @State private var showGPXPicker = false
    @State private var showGPXPreview = false
    @State private var importedGPXRoute: GPXRoute?
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
                Text(localized: "record.selectMode")
                    .font(.inter(28, weight: .black))
                    .italic()
                    .foregroundStyle(.stravaOrange)
                    .padding(.top, 24)

                Text(localized: "record.selectMode.subtitle")
                    .font(.inter(15, weight: .regular))
                    .foregroundStyle(.gravel)
                    .padding(.top, 8)

                // Mode cards
                VStack(spacing: 14) {
                    ForEach(RecordMode.allCases) { mode in
                        RecordModeCard(mode: mode) {
                            if mode == .gpx {
                                showGPXPicker = true
                            } else if mode == .liveOverlay {
                                showLiveOverlay = true
                            } else if mode == .dataOnly {
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
        .fullScreenCover(isPresented: $showLiveOverlay) {
            LiveOverlayView(onCloseAll: { showLiveOverlay = false })
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
                            LiveTrackingView(onCloseAll: { showTrackingConfig = false })
                                .navigationBarBackButtonHidden(true)
                        case .routeSetup:
                            RouteSetupView(path: $trackingPath)
                        case .waitingForStart(let start, let end):
                            WaitingForStartView(startCoordinate: start, endCoordinate: end, path: $trackingPath)
                        case .scheduledRecording(let end):
                            LiveTrackingView(endCoordinate: end, onCloseAll: { showTrackingConfig = false })
                                .navigationBarBackButtonHidden(true)
                        default:
                            EmptyView()
                        }
                    }
            }
        }
        .fileImporter(
            isPresented: $showGPXPicker,
            allowedContentTypes: [UTType(filenameExtension: "gpx") ?? .xml],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                if let parsed = GPXParser.parse(url: url) {
                    importedGPXRoute = parsed
                    showGPXPreview = true
                }
            case .failure(let error):
                print("[GPX] Import failed: \(error.localizedDescription)")
            }
        }
        .fullScreenCover(isPresented: $showGPXPreview) {
            if let route = importedGPXRoute {
                GPXPreviewView(
                    routeName: route.name,
                    coordinates: route.coordinates,
                    gpxRoute: route,
                    onClose: { showGPXPreview = false }
                )
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

                // Arrow or lock
                Image(systemName: mode.isLocked ? "lock.fill" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(mode.isLocked ? .gravel.opacity(0.8) : mode.isHighlighted ? .stravaOrange : .gravel.opacity(0.8))
            }
            .padding(16)
            .background(mode.isLocked ? Color.white.opacity(0.5) : mode.isHighlighted ? Color.stravaOrange.opacity(0.08) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(mode.isHighlighted ? Color.stravaOrange.opacity(0.2) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(mode.isLocked)
    }
}

#Preview {
    NavigationStack {
        RecordView()
    }
    .environment(MainTabCoordinator())
}
