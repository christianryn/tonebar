import Combine
import CoreAudio
import Foundation

@MainActor
final class AudioSessionController: ObservableObject {
    @Published var mode: EQMode = .allSystem
    @Published var isEnabled = false
    @Published var selectedProcessID: AudioObjectID?
    @Published private(set) var processes: [AudioProcess] = []
    @Published var bandGains: [Float] = Array(repeating: 0, count: 10)
    @Published var outputGain: Float = 0
    @Published private(set) var statusMessage = "EQ off"
    @Published var lastError: String?

    let bandLabels = ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]

    private let tap = SystemAudioTap()
    private let pipeline = AudioPipeline()
    private let deviceMonitor = DeviceMonitor()
    private var ringBuffer: RingBuffer?

    init() {
        refreshProcesses()
        deviceMonitor.onDefaultOutputChanged = { [weak self] in
            Task { @MainActor in
                self?.reconfigureIfRunning()
            }
        }
    }

    func refreshProcesses() {
        processes = ProcessEnumerator.fetchProcesses()
        if let selectedProcessID,
           !processes.contains(where: { $0.processObjectID == selectedProcessID }) {
            self.selectedProcessID = nil
        }
    }

    func setBandGain(index: Int, gain: Float) {
        guard bandGains.indices.contains(index) else { return }
        bandGains[index] = gain
        pipeline.setBandGain(index: index, gain: gain)
    }

    func updateOutputGain(_ gain: Float) {
        outputGain = gain
        pipeline.outputGain = gain
    }

    func start() {
        lastError = nil
        do {
            try startSession()
            deviceMonitor.start()
            statusMessage = mode == .allSystem ? "EQ on — all audio" : "EQ on — selected app"
        } catch {
            lastError = error.localizedDescription
            statusMessage = "Failed to start"
            isEnabled = false
            stop()
        }
    }

    func stop() {
        tap.stop()
        pipeline.stop()
        ringBuffer?.reset()
        deviceMonitor.stop()
        statusMessage = "EQ off"
    }

    func reconfigure() {
        reconfigureIfRunning()
    }

    private func reconfigureIfRunning() {
        guard isEnabled else { return }
        stop()
        start()
    }

    private func startSession() throws {
        let configuration = try makeTapConfiguration()
        try tap.start(configuration: configuration)

        guard let format = tap.streamFormat else {
            throw SystemAudioTapError.formatQueryFailed(-1)
        }

        let channels = Int(format.channelCount)
        let ring = RingBuffer(frameCapacity: Int(format.sampleRate * 0.1), channelCount: channels)
        ringBuffer = ring

        tap.onPCMBuffer = { samples, count in
            _ = ring.write(samples, count: count)
        }

        try pipeline.configure(format: format, ringBuffer: ring)
        for (index, gain) in bandGains.enumerated() {
            pipeline.setBandGain(index: index, gain: gain)
        }
        pipeline.outputGain = outputGain
    }

    private func makeTapConfiguration() throws -> TapConfiguration {
        switch mode {
        case .allSystem:
            return .global(excludingProcessObjectIDs: [])
        case .selectedApp:
            guard let selectedProcessID else {
                throw SessionError.noProcessSelected
            }
            return .processes([selectedProcessID])
        }
    }
}

enum SessionError: LocalizedError {
    case noProcessSelected

    var errorDescription: String? {
        switch self {
        case .noProcessSelected:
            return "Select an application before enabling EQ."
        }
    }
}
