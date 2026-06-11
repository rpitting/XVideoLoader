import SwiftUI

@main
struct XVideoLoaderApp: App {

    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        MenuBarExtra("X Video Loader", systemImage: "arrow.down.circle.fill") {
            ContentView()
                .environmentObject(authManager)
        }
        .menuBarExtraStyle(.window)

        Window("X Login", id: "auth") {
            AuthWindow()
                .environmentObject(authManager)
        }
        .windowResizability(.contentSize)
    }
}
