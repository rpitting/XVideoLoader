import SwiftUI

@main
struct XVideoLoaderApp: App {

    private let authManager = AuthManager()

    var body: some Scene {
        MenuBarExtra("X Video Loader", systemImage: "arrow.down.circle.fill") {
            ContentView(viewModel: DownloaderViewModel(authManager: authManager))
        }
        .menuBarExtraStyle(.window)

        Window("X Login", id: "auth") {
            AuthWindow()
                .environmentObject(authManager)
        }
        .windowResizability(.contentSize)
    }
}
