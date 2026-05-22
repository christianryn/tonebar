import SwiftUI

@main
struct ToneBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var session = AudioSessionController()

    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .environmentObject(session)
        }
        .defaultSize(width: 400, height: 280)

        MenuBarExtra("ToneBar", systemImage: "slider.horizontal.3") {
            MenuBarView()
                .environmentObject(session)
        }
        .menuBarExtraStyle(.window)
    }
}
