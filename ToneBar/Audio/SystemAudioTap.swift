import AVFAudio
import CoreAudio
import Foundation

enum SystemAudioTapError: LocalizedError {
    case tapCreationFailed(OSStatus)
    case aggregateDeviceCreationFailed(OSStatus)
    case ioProcRegistrationFailed(OSStatus)
    case startFailed(OSStatus)
    case formatQueryFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .tapCreationFailed(let status):
            return "Failed to create audio tap (OSStatus \(status))."
        case .aggregateDeviceCreationFailed(let status):
            return "Failed to create aggregate device (OSStatus \(status))."
        case .ioProcRegistrationFailed(let status):
            return "Failed to register IO proc (OSStatus \(status))."
        case .startFailed(let status):
            return "Failed to start audio tap (OSStatus \(status))."
        case .formatQueryFailed(let status):
            return "Failed to read tap format (OSStatus \(status))."
        }
    }
}

/// Manages CATap lifecycle: process tap, private aggregate device, and IOProc capture.
final class SystemAudioTap {
    private(set) var tapID: AudioObjectID = .init(kAudioObjectUnknown)
    private(set) var aggregateDeviceID: AudioObjectID = .init(kAudioObjectUnknown)
    private var ioProcID: AudioDeviceIOProcID?
    private(set) var streamFormat: AVAudioFormat?

    var onPCMBuffer: ((UnsafePointer<Float>, Int) -> Void)?

    func start(configuration: TapConfiguration) throws {
        stop()
        try createTap(configuration: configuration)
        try createAggregateDevice()
        try readStreamFormat()
        try registerIOProc()
        try startIO()
    }

    func stop() {
        if let ioProcID, aggregateDeviceID != kAudioObjectUnknown {
            AudioDeviceStop(aggregateDeviceID, ioProcID)
            AudioDeviceDestroyIOProcID(aggregateDeviceID, ioProcID)
        }
        self.ioProcID = nil

        if aggregateDeviceID != kAudioObjectUnknown {
            AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            aggregateDeviceID = .init(kAudioObjectUnknown)
        }

        if tapID != kAudioObjectUnknown {
            AudioHardwareDestroyProcessTap(tapID)
            tapID = .init(kAudioObjectUnknown)
        }

        streamFormat = nil
    }

    deinit {
        stop()
    }

    private func createTap(configuration: TapConfiguration) throws {
        let description = configuration.makeTapDescription(name: "ToneBar Tap")
        var newTapID = AudioObjectID(kAudioObjectUnknown)
        let status = AudioHardwareCreateProcessTap(description, &newTapID)
        guard status == noErr else {
            throw SystemAudioTapError.tapCreationFailed(status)
        }
        tapID = newTapID
    }

    private func createAggregateDevice() throws {
        let deviceUID = UUID().uuidString
        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey: "ToneBar Aggregate",
            kAudioAggregateDeviceUIDKey: deviceUID,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceIsStackedKey: false,
        ]

        var newDeviceID = AudioObjectID(kAudioObjectUnknown)
        let createStatus = AudioHardwareCreateAggregateDevice(description as CFDictionary, &newDeviceID)
        guard createStatus == noErr else {
            throw SystemAudioTapError.aggregateDeviceCreationFailed(createStatus)
        }
        aggregateDeviceID = newDeviceID

        try attachTapToAggregateDevice()
    }

    private func attachTapToAggregateDevice() throws {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioAggregateDevicePropertyTapList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var tapUID: CFString = "" as CFString
        var uidSize = UInt32(MemoryLayout<CFString>.stride)
        var uidAddress = AudioObjectPropertyAddress(
            mSelector: kAudioTapPropertyUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let uidStatus = withUnsafeMutablePointer(to: &tapUID) { pointer in
            AudioObjectGetPropertyData(tapID, &uidAddress, 0, nil, &uidSize, pointer)
        }
        guard uidStatus == noErr else {
            throw SystemAudioTapError.formatQueryFailed(uidStatus)
        }

        var propertySize: UInt32 = 0
        AudioObjectGetPropertyDataSize(aggregateDeviceID, &propertyAddress, 0, nil, &propertySize)

        var tapList: [CFString] = []
        if propertySize > 0 {
            var existingList: CFArray?
            _ = withUnsafeMutablePointer(to: &existingList) { pointer in
                AudioObjectGetPropertyData(aggregateDeviceID, &propertyAddress, 0, nil, &propertySize, pointer)
            }
            if let existing = existingList as? [CFString] {
                tapList = existing
            }
        }

        if !tapList.contains(where: { $0 as String == tapUID as String }) {
            tapList.append(tapUID)
        }

        propertySize = UInt32(MemoryLayout<CFString>.stride * tapList.count)
        var listCF = tapList as CFArray
        let setStatus = withUnsafeMutablePointer(to: &listCF) { pointer in
            AudioObjectSetPropertyData(aggregateDeviceID, &propertyAddress, 0, nil, propertySize, pointer)
        }
        guard setStatus == noErr else {
            throw SystemAudioTapError.aggregateDeviceCreationFailed(setStatus)
        }
    }

    private func readStreamFormat() throws {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioTapPropertyFormat,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var asbd = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        let status = AudioObjectGetPropertyData(tapID, &propertyAddress, 0, nil, &size, &asbd)
        guard status == noErr else {
            throw SystemAudioTapError.formatQueryFailed(status)
        }
        streamFormat = AVAudioFormat(streamDescription: &asbd)
    }

    private func registerIOProc() throws {
        var procID: AudioDeviceIOProcID?
        // Block order: inNow, inInputData, inInputTime, outOutputData, inOutputTime
        let status = AudioDeviceCreateIOProcIDWithBlock(&procID, aggregateDeviceID, nil) { [weak self] _, inInputData, _, _, _ in
            guard let self else { return }
            let bufferList = UnsafeMutableAudioBufferListPointer(
                UnsafeMutablePointer(mutating: inInputData)
            )
            guard let firstBuffer = bufferList.first, let data = firstBuffer.mData else { return }
            let sampleCount = Int(firstBuffer.mDataByteSize) / MemoryLayout<Float>.size
            self.onPCMBuffer?(data.assumingMemoryBound(to: Float.self), sampleCount)
        }
        guard status == noErr, let procID else {
            throw SystemAudioTapError.ioProcRegistrationFailed(status)
        }
        ioProcID = procID
    }

    private func startIO() throws {
        guard let ioProcID else {
            throw SystemAudioTapError.startFailed(-1)
        }
        let status = AudioDeviceStart(aggregateDeviceID, ioProcID)
        guard status == noErr else {
            throw SystemAudioTapError.startFailed(status)
        }
    }
}
