import SwiftUI

enum TrackingMode: String, CaseIterable, Identifiable {
    case freeRecord
    case scheduled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .freeRecord: LanguageManager.shared.localizedString("tracking.freeRecord")
        case .scheduled: LanguageManager.shared.localizedString("tracking.scheduled")
        }
    }

    var subtitle: String {
        switch self {
        case .freeRecord: LanguageManager.shared.localizedString("tracking.freeRecord.subtitle")
        case .scheduled: LanguageManager.shared.localizedString("tracking.scheduled.subtitle")
        }
    }

    var icon: String {
        switch self {
        case .freeRecord: "play.fill"
        case .scheduled: "point.topleft.down.to.point.bottomright.curvepath.fill"
        }
    }
}

struct TrackingConfigView: View {
    @State private var selected: TrackingMode = .freeRecord
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [RecordRoute]

    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image("back")
                        .renderingMode(.template)
                        .foregroundStyle(.gravel)
                }

                Spacer()

                Text(localized: "tracking.configTitle")
                    .font(.inter(14, weight: .black))
                    .tracking(1)
                    .foregroundStyle(.white)

                Spacer()

                // Balance spacer
                Image("back")
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // Mode cards
            VStack(spacing: 14) {
                ForEach(TrackingMode.allCases) { mode in
                    trackingCard(mode: mode)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)

            Spacer()

            // Confirm button
            Button {
                if selected == .freeRecord {
                    path.append(.countdown)
                } else if selected == .scheduled {
                    path.append(.routeSetup)
                }
            } label: {
                HStack(spacing: 8) {
                    Text(localized: "tracking.confirm")
                        .font(.inter(15, weight: .black))
                        .tracking(1)
                    Image("start")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(.stravaOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(.black)
        .navigationBarHidden(true)
        .swipeBack {
            dismiss()
        }
    }

    private func trackingCard(mode: TrackingMode) -> some View {
        Button {
            selected = mode
        } label: {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(mode.title)
                        .font(.inter(16, weight: .black))
                        .foregroundStyle(.white)
                    Text(mode.subtitle)
                        .font(.inter(13, weight: .regular))
                        .foregroundStyle(.gravel)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: mode.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(selected == mode ? .stravaOrange : .gravel)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected == mode ? Color.stravaOrange : Color.white.opacity(0.08), lineWidth: selected == mode ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                TrackingConfigView(path: .constant([]))
            }
    }
}
