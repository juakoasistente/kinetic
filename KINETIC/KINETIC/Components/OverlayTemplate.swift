import SwiftUI

// MARK: - Overlay Template

enum OverlayTemplate: String, CaseIterable, Identifiable {
    case classic    // Current: big speed center-bottom, stats row, buttons
    case minimal    // Speed bottom-left, time top-right, nothing else
    case dashboard  // Racing style: speed arc top, 4-stat bar bottom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: "Classic"
        case .minimal: "Minimal"
        case .dashboard: "Dashboard"
        }
    }

    var description: String {
        switch self {
        case .classic: "Full telemetry with speed, stats and controls"
        case .minimal: "Clean look — just speed and time"
        case .dashboard: "Racing HUD with all data"
        }
    }

    var icon: String {
        switch self {
        case .classic: "speedometer"
        case .minimal: "eye"
        case .dashboard: "gauge.open.with.lines.needle.33percent"
        }
    }
}

// MARK: - Overlay Template Picker

struct OverlayTemplatePickerView: View {
    @Binding var selected: OverlayTemplate
    var onConfirm: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            Text(LanguageManager.shared.localizedString("overlay.chooseOverlay"))
                .font(.inter(12, weight: .bold))
                .tracking(2)
                .foregroundStyle(.gravel)

            Text(LanguageManager.shared.localizedString("overlay.overlaySubtitle"))
                .font(.inter(14, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 8)

            // Template previews
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(OverlayTemplate.allCases) { template in
                        templateCard(template)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }

            // Confirm
            Button(action: onConfirm) {
                HStack(spacing: 8) {
                    Text(LanguageManager.shared.localizedString("overlay.continue"))
                        .font(.inter(15, weight: .black))
                        .tracking(1)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.stravaOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(.black)
    }

    private func templateCard(_ template: OverlayTemplate) -> some View {
        let isSelected = selected == template

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selected = template }
        } label: {
            VStack(spacing: 12) {
                // Preview thumbnail — large
                overlayPreviewThumb(template)
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.displayName)
                            .font(.inter(16, weight: .bold))
                            .foregroundStyle(isSelected ? .white : .gravel)
                        Text(template.description)
                            .font(.inter(13, weight: .regular))
                            .foregroundStyle(isSelected ? .white.opacity(0.6) : .gravel.opacity(0.6))
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.stravaOrange)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color.stravaOrange.opacity(0.12) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.stravaOrange.opacity(0.4) : .clear, lineWidth: 1)
            )
        }
    }

    // Preview of each overlay style
    private func overlayPreviewThumb(_ template: OverlayTemplate) -> some View {
        ZStack {
            Color(hex: 0x2A2A2E)

            switch template {
            case .classic:
                VStack(spacing: 6) {
                    Spacer()
                    Text("87")
                        .font(.inter(36, weight: .black))
                        .foregroundStyle(.white)
                    Text("KM/H")
                        .font(.inter(10, weight: .bold))
                        .foregroundStyle(.stravaOrange)
                    HStack(spacing: 8) {
                        miniStat("MAX", "142")
                        miniStat("AVG", "76")
                        miniStat("DIST", "12.4")
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }

            case .minimal:
                VStack {
                    HStack {
                        Spacer()
                        Text("14:32")
                            .font(.inter(12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(8)
                    }
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("87")
                                .font(.inter(36, weight: .black))
                                .foregroundStyle(.white)
                            Text("KM/H")
                                .font(.inter(10, weight: .bold))
                                .foregroundStyle(.stravaOrange)
                        }
                        .padding(12)
                        Spacer()
                    }
                }

            case .dashboard:
                VStack(spacing: 4) {
                    Text("87")
                        .font(.inter(32, weight: .black))
                        .foregroundStyle(.stravaOrange)
                        .padding(.top, 16)
                    Text("KM/H")
                        .font(.inter(8, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    HStack(spacing: 4) {
                        miniStat("MAX", "142")
                        miniStat("AVG", "76")
                        miniStat("DIST", "12.4")
                        miniStat("TIME", "14:32")
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.inter(7, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.inter(12, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Overlay Views per Template

struct MinimalOverlayView: View {
    let speed: Int
    let time: String
    let isRecording: Bool
    var onStop: () -> Void = {}
    private let settings = OverlaySettings.shared

    var body: some View {
        VStack {
            // Top: time + REC
            HStack {
                if isRecording {
                    HStack(spacing: 6) {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text(LanguageManager.shared.localizedString("overlay.rec")).font(.inter(12, weight: .bold)).foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.black.opacity(0.5)).clipShape(Capsule())
                }
                Spacer()
                if settings.showTime {
                    Text(time)
                        .font(.inter(16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.black.opacity(0.5)).clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20).padding(.top, 60)

            Spacer()

            // Bottom: speed left, stop right
            HStack(alignment: .bottom) {
                if settings.showSpeed {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(speed)")
                            .font(.inter(64, weight: .black))
                            .foregroundStyle(.white)
                        Text(LanguageManager.shared.localizedString("overlay.kmh"))
                            .font(.inter(14, weight: .bold))
                            .foregroundStyle(.stravaOrange)
                    }
                    .shadow(color: .black.opacity(0.6), radius: 6, y: 3)
                }

                Spacer()

                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.stravaOrange)
                        .clipShape(Circle())
                }
            }
            .padding(24)
        }
    }
}

struct DashboardOverlayView: View {
    let speed: Int
    let maxSpeed: Int
    let avgSpeed: Int
    let distance: String
    let time: String
    let isRecording: Bool
    var onPause: () -> Void = {}
    var onStop: () -> Void = {}
    private let settings = OverlaySettings.shared

    var body: some View {
        VStack(spacing: 0) {
            // Top: REC indicator
            HStack {
                if isRecording {
                    HStack(spacing: 6) {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text(LanguageManager.shared.localizedString("overlay.rec")).font(.inter(12, weight: .bold)).foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.black.opacity(0.5)).clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 60)

            // Speed display — centered, racing style
            if settings.showSpeed {
                VStack(spacing: 4) {
                    Text("\(speed)")
                        .font(.inter(80, weight: .black))
                        .foregroundStyle(.stravaOrange)
                    Text(LanguageManager.shared.localizedString("overlay.kmh"))
                        .font(.inter(14, weight: .bold))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
                .padding(.top, 20)
            }

            Spacer()

            // Bottom: stat bar + buttons
            VStack(spacing: 12) {
                let visibleStats = dashStatsToShow
                if !visibleStats.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(visibleStats, id: \.label) { stat in
                            dashStat(label: stat.label, value: stat.value, unit: stat.unit)
                        }
                    }
                }

                HStack(spacing: 16) {
                    Button(action: onPause) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.stravaOrange)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(16)
            .background(.black.opacity(0.6))
        }
    }

    private struct DashStatItem: Hashable {
        let label: String
        let value: String
        let unit: String
    }

    private var dashStatsToShow: [DashStatItem] {
        var stats: [DashStatItem] = []
        if settings.showMaxSpeed { stats.append(DashStatItem(label: "MAX", value: "\(maxSpeed)", unit: "KM/H")) }
        if settings.showAvgSpeed { stats.append(DashStatItem(label: "AVG", value: "\(avgSpeed)", unit: "KM/H")) }
        if settings.showDistance { stats.append(DashStatItem(label: "DIST", value: distance, unit: "KM")) }
        if settings.showTime { stats.append(DashStatItem(label: "TIME", value: time, unit: "")) }
        return stats
    }

    private func dashStat(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.inter(8, weight: .bold))
                .foregroundStyle(.stravaOrange.opacity(0.7))
            Text(value)
                .font(.inter(18, weight: .bold))
                .foregroundStyle(.white)
            if !unit.isEmpty {
                Text(unit)
                    .font(.inter(7, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Previews

#Preview("Template Picker") {
    OverlayTemplatePickerView(
        selected: .constant(.classic),
        onConfirm: {},
        onBack: {}
    )
}

#Preview("Minimal Overlay") {
    ZStack {
        Color(hex: 0x1A1A1A).ignoresSafeArea()
        MinimalOverlayView(speed: 87, time: "00:14:32", isRecording: true)
    }
}

#Preview("Dashboard Overlay") {
    ZStack {
        Color(hex: 0x1A1A1A).ignoresSafeArea()
        DashboardOverlayView(
            speed: 87, maxSpeed: 142, avgSpeed: 76,
            distance: "12.4", time: "14:32", isRecording: true
        )
    }
}
