internal import Combine
import Foundation
import WebKit

@MainActor
class AuthManager: ObservableObject {
    @Published var isLoggedIn = false

    private let cookiesFileURL: URL

    init() {
        let appSupport = URL.applicationSupportDirectory.appendingPathComponent("XVideoLoader")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        cookiesFileURL = appSupport.appendingPathComponent("cookies.txt")
        isLoggedIn = FileManager.default.fileExists(atPath: cookiesFileURL.path)
    }

    var cookiesFilePath: String {
        cookiesFileURL.path
    }

    func saveCookies(from cookieStore: WKHTTPCookieStore) async {
        let all = await cookieStore.allCookies()
        let relevant = all.filter {
            $0.domain.contains("x.com") || $0.domain.contains("twitter.com")
        }
        guard !relevant.isEmpty else { return }

        var lines = [
            "# Netscape HTTP Cookie File",
            "# https://curl.se/docs/http-cookies.html",
            ""
        ]
        for c in relevant {
            let includesSubs = c.domain.hasPrefix(".") ? "TRUE" : "FALSE"
            let secure       = c.isSecure ? "TRUE" : "FALSE"
            let expires      = Int(c.expiresDate?.timeIntervalSince1970 ?? 0)
            lines.append("\(c.domain)\t\(includesSubs)\t\(c.path)\t\(secure)\t\(expires)\t\(c.name)\t\(c.value)")
        }

        try? lines.joined(separator: "\n").write(to: cookiesFileURL, atomically: true, encoding: .utf8)
        isLoggedIn = true
    }

    func logout() {
        try? FileManager.default.removeItem(at: cookiesFileURL)
        isLoggedIn = false
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast,
            completionHandler: {}
        )
    }
}
