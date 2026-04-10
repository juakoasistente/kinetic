import SwiftUI

// MARK: - Onboarding Page Data

struct OnboardingPage: Identifiable {
    let id: Int
    let titleKey: String
    let highlightKey: String
    let subtitleKey: String
    let backgroundImage: String // Single custom background per page
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        id: 0,
        titleKey: "onboarding.1.title",
        highlightKey: "onboarding.1.highlight",
        subtitleKey: "onboarding.1.subtitle",
        backgroundImage: "onboarding1"
    ),
    OnboardingPage(
        id: 1,
        titleKey: "onboarding.2.title",
        highlightKey: "onboarding.2.highlight",
        subtitleKey: "onboarding.2.subtitle",
        backgroundImage: "onboarding2"
    ),
    OnboardingPage(
        id: 2,
        titleKey: "onboarding.3.title",
        highlightKey: "onboarding.3.highlight",
        subtitleKey: "onboarding.3.subtitle",
        backgroundImage: "onboarding3"
    ),
    OnboardingPage(
        id: 3,
        titleKey: "onboarding.4.title",
        highlightKey: "onboarding.4.highlight",
        subtitleKey: "onboarding.4.subtitle",
        backgroundImage: "onboarding4"
    ),
]

// MARK: - Onboarding View

struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(onboardingPages) { page in
                    OnboardingPageView(
                        page: page,
                        isLastPage: page.id == onboardingPages.count - 1,
                        onNext: { advanceOrFinish() },
                        onSkip: { onFinished() }
                    )
                    .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
    }

    private func advanceOrFinish() {
        if currentPage < onboardingPages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            onFinished()
        }
    }
}

// MARK: - Single Page

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    var onNext: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            // Custom background image per page
            GeometryReader { geo in
                if UIImage(named: page.backgroundImage) != nil {
                    Image(page.backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .blur(radius: 2)
                        .overlay(Color.black.opacity(0.3))
                } else {
                    Color(hex: 0x1A1A1E)
                        .overlay {
                            Image(systemName: "car.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.white.opacity(0.05))
                        }
                }
            }
            .ignoresSafeArea()

            // Gradient from bottom
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7), .black, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 450)
            }
            .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Skip button — top right
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button(action: onSkip) {
                            Text(LanguageManager.shared.localizedString("onboarding.skip"))
                                .font(.inter(13, weight: .semibold))
                                .tracking(1)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.trailing, 24)
                .padding(.top, 16)

                Spacer()

                // Bottom text + controls
                VStack(alignment: .leading, spacing: 0) {
                    // Title
                    VStack(alignment: .leading, spacing: 0) {
                        Text(LanguageManager.shared.localizedString(page.titleKey))
                            .font(.inter(36, weight: .black))
                            .italic()
                            .foregroundStyle(.white)

                        Text(LanguageManager.shared.localizedString(page.highlightKey))
                            .font(.inter(36, weight: .black))
                            .italic()
                            .foregroundStyle(Color.stravaOrange)
                    }

                    // Subtitle
                    Text(LanguageManager.shared.localizedString(page.subtitleKey))
                        .font(.inter(15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineSpacing(4)
                        .padding(.top, 16)

                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == page.id ? Color.stravaOrange : Color.white.opacity(0.3))
                                .frame(width: index == page.id ? 24 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: page.id)
                        }
                    }
                    .padding(.top, 32)

                    // Button
                    Button(action: onNext) {
                        HStack(spacing: 8) {
                            Text(LanguageManager.shared.localizedString(
                                isLastPage ? "onboarding.start" : "onboarding.next"
                            ))
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
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Previews

#Preview("Page 1 - Community") {
    OnboardingPageView(
        page: onboardingPages[0],
        isLastPage: false,
        onNext: {},
        onSkip: {}
    )
}

#Preview("Page 2 - Record") {
    OnboardingPageView(
        page: onboardingPages[1],
        isLastPage: false,
        onNext: {},
        onSkip: {}
    )
}

#Preview("Page 3 - Share") {
    OnboardingPageView(
        page: onboardingPages[2],
        isLastPage: false,
        onNext: {},
        onSkip: {}
    )
}

#Preview("Page 4 - Privacy") {
    OnboardingPageView(
        page: onboardingPages[3],
        isLastPage: true,
        onNext: {},
        onSkip: {}
    )
}

#Preview("Full Onboarding") {
    OnboardingView(onFinished: {})
}
