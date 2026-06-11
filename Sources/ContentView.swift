import SwiftUI

struct ContentView: View {

    @State var viewModel: DownloaderViewModel

    @Environment(\.openWindow) private var openWindow

    @FocusState private var urlFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // yt-dlp Status
            HStack(spacing: 6) {
                Image(systemName: viewModel.downloader.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(viewModel.downloader.isAvailable ? .green : .red)
                Text(viewModel.downloader.isAvailable ? "yt-dlp bereit" : "yt-dlp nicht gefunden")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !viewModel.downloader.isAvailable {
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
                Image(systemName: viewModel.isLoggedIn ? "person.fill.checkmark" : "person.fill.xmark")
                    .foregroundStyle(viewModel.isLoggedIn ? .green : .secondary)
                Text(viewModel.isLoggedIn ? "Angemeldet bei X" : "Nicht angemeldet")
                    .font(.caption)
                    .foregroundStyle(viewModel.isLoggedIn ? .primary : .secondary)
                Spacer()
                if viewModel.isLoggedIn {
                    Button("Abmelden") {
                        viewModel.logout()
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
            VStack(alignment: .leading) {
                Text("Video-URL")
                    .font(.caption)
                TextField("https://x.com/…", text: $viewModel.urlText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.downloader.isDownloading)
                    .focused($urlFieldFocused)
            }

            // Download-Button
            Button(action: viewModel.startDownload) {
                HStack {
                    if viewModel.downloader.isDownloading {
                        ProgressView().controlSize(.small)
                        if viewModel.downloader.progress > 0 {
                            Text("\(Int(viewModel.downloader.progress)) %")
                                .monospacedDigit()
                        } else {
                            Text(viewModel.downloader.statusMessage)
                        }
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Herunterladen")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canDownload)

            if viewModel.downloader.isDownloading {
                ProgressView(value: viewModel.downloader.progress, total: 100)
                    .progressViewStyle(.linear)
            }

            // Ergebnis / Fehler
            if !viewModel.resultMessage.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: viewModel.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(viewModel.isError ? .red : .green)
                    Text(viewModel.resultMessage)
                        .font(.caption)
                        .foregroundStyle(viewModel.isError ? .red : .primary)
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
                await viewModel.updateHelperAvailability()
            }
        }
        .padding()
        .frame(width: 320)
    }
}
#Preview {
    ContentView(viewModel: DownloaderViewModel(authManager: AuthManager()))
        .background(.regularMaterial,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
        .padding(40)
        .frame(width: 440, height: 560)
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.18, blue: 0.32),
                    Color(red: 0.28, green: 0.18, blue: 0.40),
                    Color(red: 0.55, green: 0.25, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
}
