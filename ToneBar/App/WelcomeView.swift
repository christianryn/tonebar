import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "slider.horizontal.3")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ToneBar is running")
                        .font(.title2.bold())
                    Text("macOS menu bar equalizer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Label("Click the slider icon in the menu bar (top-right of the screen).", systemImage: "menubar.arrow.up.rectangle")
            Label("Turn **On**, pick **All Audio** or **Selected App**, then play music.", systemImage: "power")
            Label("Grant **Screen & System Audio Recording** when macOS asks.", systemImage: "lock.shield")

            Text("You can close this window — ToneBar keeps running in the menu bar.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Open Menu Bar Panel") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 380, minHeight: 260)
    }
}
