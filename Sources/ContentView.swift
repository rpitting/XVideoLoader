import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var downloader = Downloader()
    @Environment(\.openWindow) private var openWindow

    @State private var urlText = ""
    @State private var resultMessage = ""
    @State private var isError = false
    @FocusState private var urlFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // yt-dlp Status
            HStack(spacing: 6) {
                Image(systemName: downloader.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(downloader.isAvailable ? .green : .red)
                Text(downloader.isAvailable ? "yt-dlp bereit" : "yt-dlp nicht gefunden")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !downloader.isAvailable {
                    Button("Installieren") {
                        NSWorkspace.shared.open(URL(string: "https://brew.sh")!)
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }

            Divider()

            // Login-Status
            HStack(spacing: 8) {
                Image(systemName: authManager.isLoggedIn ? "person.fill.checkmark" : "person.fill.xmark")
                    .foregroundStyle(authManager.isLoggedIn ? .green : .secondary)
                Text(authManager.isLoggedIn ? "Angemeldet bei X" : "Nicht angemeldet")
                    .font(.caption)
                    .foregroundStyle(authManager.isLoggedIn ? .primary : .secondary)
                Spacer()
                if authManager.isLoggedIn {
                    Button("Abmelden") {
                        authManager.logout()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    .foregroundStyle(.red)
                } else {
                    Button("Anmelden…") {
                        openWindow(id: "auth")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            Divider()

            // URL-Eingabe
            VStack(alignment: .leading, spacing: 4) {
                Text("Video-URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("https://x.com/…", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(downloader.isDownloading)
                    .focused($urlFieldFocused)
            }

            // Download-Button
            Button(action: startDownload) {
                HStack {
                    if downloader.isDownloading {
                        ProgressView().controlSize(.small)
                        if downloader.progress > 0 {
                            Text("\(Int(downloader.progress)) %")
                                .monospacedDigit()
                        } else {
                            Text(downloader.statusMessage)
                        }
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Herunterladen")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canDownload)

            if downloader.isDownloading {
                ProgressView(value: downloader.progress, total: 100)
                    .progressViewStyle(.linear)
            }

            // Ergebnis / Fehler
            if !resultMessage.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(isError ? .red : .green)
                    Text(resultMessage)
                        .font(.caption)
                        .foregroundStyle(isError ? .red : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Beenden") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.link)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear() {
            urlFieldFocused = true

            Task {
                await downloader.updateHelperAvailability()
            }
        }
        .padding()
        .frame(width: 320)
    }

    private var canDownload: Bool {
        downloader.isAvailable &&
        !urlText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !downloader.isDownloading
    }

    private func startDownload() {
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
}
