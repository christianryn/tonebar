import AppKit
import CoreAudio

struct AudioProcess: Identifiable, Hashable {
    let processObjectID: AudioObjectID
    let pid: pid_t
    let name: String

    var id: AudioObjectID { processObjectID }
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
        let name = resolveName(objectID: objectID, pid: pid)
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

    private static func readBundleID(_ objectID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyBundleID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var bundleID: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.stride)
        let status = withUnsafeMutablePointer(to: &bundleID) { pointer in
            AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, pointer)
        }
        guard status == noErr else { return nil }
        return bundleID as String
    }

    private static func resolveName(objectID: AudioObjectID, pid: pid_t) -> String {
        if let bundleID = readBundleID(objectID),
           let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first,
           let localizedName = app.localizedName {
            return localizedName
        }
        return "PID \(pid)"
    }
}
