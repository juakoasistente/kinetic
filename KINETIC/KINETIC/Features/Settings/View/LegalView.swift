import SwiftUI
import WebKit
import Supabase

enum LegalType: Identifiable {
    case terms
    case privacy

    var id: String {
        switch self {
        case .terms: "terms"
        case .privacy: "privacy"
        }
    }

    var badge: String { LanguageManager.shared.localizedString("legal.badge") }

    var title: String {
        switch self {
        case .terms: LanguageManager.shared.localizedString("legal.terms.title")
        case .privacy: LanguageManager.shared.localizedString("legal.privacy.title")
        }
    }

    var highlightedTitle: String {
        switch self {
        case .terms: LanguageManager.shared.localizedString("legal.terms.highlightedTitle")
        case .privacy: LanguageManager.shared.localizedString("legal.privacy.highlightedTitle")
        }
    }

    var subtitle: String {
        switch self {
        case .terms: LanguageManager.shared.localizedString("legal.terms.subtitle")
        case .privacy: LanguageManager.shared.localizedString("legal.privacy.subtitle")
        }
    }

    var backTitle: String {
        switch self {
        case .terms: LanguageManager.shared.localizedString("legal.terms.backTitle")
        case .privacy: LanguageManager.shared.localizedString("legal.privacy.backTitle")
        }
    }

    var htmlFileName: String {
        switch self {
        case .terms: "terms"
        case .privacy: "privacy"
        }
    }
}

struct LegalView: View {
    let type: LegalType
    @State private var htmlContent: String?
    @State private var isLoading = true
    @State private var webViewHeight: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image("back")
                        Text(type.backTitle)
                            .font(.inter(16, weight: .semibold))
                            .foregroundStyle(.coal)
                    }
                }

                Spacer()

                Text("KINETIC")
                    .font(.inter(16, weight: .black))
                    .foregroundStyle(.coal)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)

            ZStack {
                // Content underneath (hidden until ready)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text(type.badge)
                                .font(.inter(11, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.stravaOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 0) {
                                Text(type.title)
                                    .font(.inter(32, weight: .bold))
                                    .foregroundStyle(.coal)
                                Text(type.highlightedTitle)
                                    .font(.inter(32, weight: .bold))
                                    .foregroundStyle(.stravaOrange)
                            }

                            RoundedRectangle(cornerRadius: 2)
                                .fill(.rust)
                                .frame(width: 60, height: 4)

                            Text(type.subtitle)
                                .font(.inter(15, weight: .regular))
                                .foregroundStyle(.gravel)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 24)

                        // HTML content
                        if let htmlContent {
                            LegalHTMLView(htmlString: htmlContent, contentHeight: $webViewHeight, onFinished: {
                                withAnimation(.easeIn(duration: 0.25)) {
                                    isLoading = false
                                }
                            })
                            .frame(height: max(webViewHeight, 100))
                            .padding(.horizontal, 24)
                        }
                    }
                }
                .opacity(isLoading ? 0 : 1)

                // Spinner on top while loading
                if isLoading {
                    Color.fog
                    SpinningView()
                }
            }
        }
        .background(.fog)
        .navigationBarHidden(true)
        .task {
            await loadHTML()
        }
    }

    private func loadHTML() async {
        // Try remote from Supabase
        if let client = SupabaseManager.shared.client {
            do {
                let url = try client.storage
                    .from("legal")
                    .getPublicURL(path: "\(type.htmlFileName).html")

                let (data, _) = try await URLSession.shared.data(from: url)
                if let html = String(data: data, encoding: .utf8) {
                    htmlContent = html
                    return
                }
            } catch {
                print("[LegalView] Failed to load remote HTML: \(error)")
            }
        }

        // Fallback
        htmlContent = "<p>Content unavailable</p>"
        isLoading = false
    }
}

// MARK: - HTML WebView

struct LegalHTMLView: UIViewRepresentable {
    let htmlString: String
    @Binding var contentHeight: CGFloat
    var onFinished: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard !context.coordinator.didLoad else { return }
        context.coordinator.didLoad = true
        webView.loadHTMLString(htmlString, baseURL: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let parent: LegalHTMLView
        var didLoad = false

        init(parent: LegalHTMLView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self?.parent.contentHeight = height
                        self?.parent.onFinished()
                    }
                }
            }
        }
    }
}

#Preview("Terms") {
    LegalView(type: .terms)
}

#Preview("Privacy") {
    LegalView(type: .privacy)
}
