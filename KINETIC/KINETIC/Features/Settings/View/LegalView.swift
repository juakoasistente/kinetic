import SwiftUI
import WebKit

enum LegalType: Identifiable {
    case terms
    case privacy

    var id: String {
        switch self {
        case .terms: "terms"
        case .privacy: "privacy"
        }
    }

    var badge: String { "LEGAL" }

    var title: String {
        switch self {
        case .terms: "Términos y"
        case .privacy: "Política de"
        }
    }

    var highlightedTitle: String {
        switch self {
        case .terms: "Condiciones"
        case .privacy: "Privacidad"
        }
    }

    var subtitle: String {
        switch self {
        case .terms:
            "Lea detenidamente estos términos antes de utilizar los servicios de Kinetic. Al acceder a nuestra plataforma, usted acepta estar sujeto a estas condiciones."
        case .privacy:
            "Su privacidad es primordial para nosotros. Este documento detalla cómo Kinetic recopila, utiliza y protege su información personal y los datos de su vehículo."
        }
    }

    var backTitle: String {
        switch self {
        case .terms: "Settings"
        case .privacy: "Configuración"
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

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        // Badge
                        Text(type.badge)
                            .font(.inter(11, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.stravaOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        // Title
                        VStack(alignment: .leading, spacing: 0) {
                            Text(type.title)
                                .font(.inter(32, weight: .bold))
                                .foregroundStyle(.coal)
                            Text(type.highlightedTitle)
                                .font(.inter(32, weight: .bold))
                                .foregroundStyle(.stravaOrange)
                        }

                        // Divider line
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.rust)
                            .frame(width: 60, height: 4)

                        // Subtitle
                        Text(type.subtitle)
                            .font(.inter(15, weight: .regular))
                            .foregroundStyle(.gravel)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                    // HTML content
                    LegalHTMLView(fileName: type.htmlFileName)
                        .frame(minHeight: 600)
                        .padding(.horizontal, 24)
                }
            }
        }
        .background(.fog)
        .navigationBarHidden(true)
    }
}

// MARK: - HTML WebView

struct LegalHTMLView: UIViewRepresentable {
    let fileName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
}

#Preview("Terms") {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                LegalView(type: .terms)
            }
    }
}

#Preview("Privacy") {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                LegalView(type: .privacy)
            }
    }
}
