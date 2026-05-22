import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var session: AudioSessionController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            modeSection
            if session.mode == .selectedApp {
                appPicker
            }
            eqSection
            statusFooter
        }
        .padding(16)
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Text("ToneBar")
                .font(.headline)
            Spacer()
            Toggle("On", isOn: $session.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: session.isEnabled) { _, enabled in
                    if enabled {
                        session.start()
                    } else {
                        session.stop()
                    }
                }
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Source")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker("Source", selection: $session.mode) {
                ForEach(EQMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: session.mode) { _, _ in
                session.reconfigure()
            }
        }
    }

    private var appPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Application")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Refresh") {
                    session.refreshProcesses()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            Picker("Application", selection: $session.selectedProcessID) {
                Text("Select an app…").tag(Optional<AudioObjectID>.none)
                ForEach(session.processes) { process in
                    Text(process.name).tag(Optional(process.processObjectID))
                }
            }
            .onChange(of: session.selectedProcessID) { _, _ in
                session.reconfigure()
            }
        }
    }

    private var eqSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Equalizer")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<session.bandGains.count, id: \.self) { index in
                    VStack(spacing: 4) {
                        Slider(
                            value: Binding(
                                get: { session.bandGains[index] },
                                set: { session.setBandGain(index: index, gain: $0) }
                            ),
                            in: -12...12
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 24, height: 80)
                        Text(session.bandLabels[index])
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            HStack {
                Text("Output")
                Slider(value: $session.outputGain, in: -12...12)
                    .onChange(of: session.outputGain) { _, gain in
                        session.updateOutputGain(gain)
                    }
                Text(String(format: "%+.0f dB", session.outputGain))
                    .monospacedDigit()
                    .frame(width: 52, alignment: .trailing)
            }
            .font(.caption)
        }
    }

    private var statusFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let error = session.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text(session.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Requires macOS 14.2+ and Screen & System Audio Recording permission.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
