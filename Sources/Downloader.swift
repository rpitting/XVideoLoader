internal import Combine
import Foundation

enum DownloaderError: LocalizedError {
    case ytdlpNotFound
    case downloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .ytdlpNotFound:
            return "yt-dlp nicht gefunden.\nBitte installieren: brew install yt-dlp"
        case .downloadFailed(let msg):
            return msg.isEmpty ? "Download fehlgeschlagen" : msg
        }
    }
}

@MainActor
class Downloader: ObservableObject {
    @Published var isAvailable = false
    @Published var isDownloading = false
    @Published var statusMessage = ""
    @Published var progress: Double = 0

    private let service: BrewService

    init() {
        service = BrewService()
        service.connect()
    }

    func updateHelperAvailability() async {
        isAvailable = await service.checkIfInstalled("yt-dlp")
    }

    func download(url: String, cookiesFilePath: String?) async throws -> String {
        guard isAvailable else {
            throw DownloaderError.ytdlpNotFound
        }

        isDownloading = true
        statusMessage = "Wird heruntergeladen..."
        progress = 0

        defer {
            isDownloading = false
            progress = 0
        }

        do {
            return try await service.download(
                url: url,
                cookiesFilePath: cookiesFilePath
            ) { [weak self] percent in
                Task { @MainActor in
                    self?.progress = percent
                }
            }
        } catch {
            throw DownloaderError.downloadFailed(error.localizedDescription)
        }
    }
}
