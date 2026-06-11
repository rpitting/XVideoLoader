import SwiftUI
import WebKit

struct AuthWebView: NSViewRepresentable {
    @ObservedObject var authManager: AuthManager
    var onSuccess: () -> Void

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: URL(string: "https://x.com/login")!))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(authManager: authManager, onSuccess: onSuccess)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        let authManager: AuthManager
        let onSuccess: () -> Void
        private var didCapture = false

        init(authManager: AuthManager, onSuccess: @escaping () -> Void) {
            self.authManager = authManager
            self.onSuccess = onSuccess
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !didCapture else { return }
            guard let host = webView.url?.host,
                  (host.contains("x.com") || host.contains("twitter.com")),
                  let path = webView.url?.path,
                  path == "/home" || path == "/" else { return }

            didCapture = true
            let store = webView.configuration.websiteDataStore.httpCookieStore
            Task { @MainActor in
                await authManager.saveCookies(from: store)
                onSuccess()
            }
        }
    }
}

// MARK: - Auth Window

struct AuthWindow: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bei X anmelden")
                    .font(.headline)
                Spacer()
                Button("Abbrechen") { dismiss() }
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            AuthWebView(authManager: authManager) {
                dismiss()
            }
        }
        .frame(width: 520, height: 680)
    }
}
