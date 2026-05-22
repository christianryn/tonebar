import Foundation

struct EQPreset: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var bandGains: [Float]
    var outputGain: Float

    init(id: UUID = UUID(), name: String, bandGains: [Float], outputGain: Float = 0) {
        self.id = id
        self.name = name
        self.bandGains = bandGains
        self.outputGain = outputGain
    }
}

enum PresetStore {
    private static var directoryURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("ToneBar", isDirectory: true)
    }

    static func loadPresets() -> [EQPreset] {
        let url = directoryURL.appendingPathComponent("presets.json")
        guard let data = try? Data(contentsOf: url) else {
            return defaultPresets()
        }
        return (try? JSONDecoder().decode([EQPreset].self, from: data)) ?? defaultPresets()
    }

    static func savePresets(_ presets: [EQPreset]) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let url = directoryURL.appendingPathComponent("presets.json")
        let data = try JSONEncoder().encode(presets)
        try data.write(to: url, options: .atomic)
    }

    static func defaultPresets() -> [EQPreset] {
        [
            EQPreset(name: "Flat", bandGains: Array(repeating: 0, count: 10)),
            EQPreset(name: "Bass Boost", bandGains: [6, 5, 4, 2, 0, 0, 0, 0, 0, 0]),
            EQPreset(name: "Voice", bandGains: [-2, -1, 0, 2, 4, 4, 2, 0, -1, -2]),
        ]
    }
}
