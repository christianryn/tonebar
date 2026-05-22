import AppKit
import CoreAudio

struct AudioProcess: Identifiable, Hashable {
    let processObjectID: AudioObjectID
    let pid: pid_t
    let name: String

    var id: pid_t { pid }
}

enum ProcessEnumerator {
    static func fetchProcesses() -> [AudioProcess] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        )
        guard status == noErr, dataSize > 0 else { return [] }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var processIDs = [AudioObjectID](repeating: 0, count: count)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &processIDs
        )
        guard status == noErr else { return [] }

        return processIDs
            .compactMap(makeProcess)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func makeProcess(_ objectID: AudioObjectID) -> AudioProcess? {
        guard let pid = readPID(objectID) else { return nil }
        let name = resolveName(pid: pid)
        return AudioProcess(processObjectID: objectID, pid: pid, name: name)
    }

    private static func readPID(_ objectID: AudioObjectID) -> pid_t? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyPID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var pid: pid_t = 0
        var size = UInt32(MemoryLayout<pid_t>.size)
        let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, &pid)
        return status == noErr ? pid : nil
    }

    private static func resolveName(pid: pid_t) -> String {
        if let app = NSRunningApplication(processIdentifier: pid) {
            if let localizedName = app.localizedName, !localizedName.isEmpty {
                return localizedName
            }
            if let bundleID = app.bundleIdentifier {
                return bundleID
            }
        }
        return "PID \(pid)"
    }
}
