import SwiftUI

@main
struct ToneBarApp: App {
    @StateObject private var session = AudioSessionController()

    var body: some Scene {
        MenuBarExtra("ToneBar", systemImage: "waveform") {
            MenuBarView()
                .environmentObject(session)
        }
        .menuBarExtraStyle(.window)
    }
}
