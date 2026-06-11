import Foundation
import SwiftUI

@MainActor
@Observable
class DownloaderViewModel {
    var urlText = ""
    private(set) var resultMessage = ""
    private(set) var isError = false

    let downloader: Downloader
    let authManager: AuthManager

    var isLoggedIn: Bool { authManager.isLoggedIn }

    init(authManager: AuthManager, downloader: Downloader? = nil) {
        self.authManager = authManager
        self.downloader = downloader ?? Downloader()
    }

    var canDownload: Bool {
        downloader.isAvailable &&
        !urlText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !downloader.isDownloading
    }

    func updateHelperAvailability() async {
        await downloader.updateHelperAvailability()
    }

    func startDownload() {
        resultMessage = ""
        isError = false
        let url = urlText.trimmingCharacters(in: .whitespaces)
        let cookiesPath = authManager.isLoggedIn ? authManager.cookiesFilePath : nil

        Task {
            do {
                let filepath = try await downloader.download(url: url, cookiesFilePath: cookiesPath)
                let filename = URL(fileURLWithPath: filepath).lastPathComponent
                downloader.statusMessage = ""
                resultMessage = filename
                isError = false
                urlText = ""
            } catch {
                downloader.statusMessage = ""
                resultMessage = error.localizedDescription
                isError = true
            }
        }
    }

    func logout() {
        authManager.logout()
    }
}
