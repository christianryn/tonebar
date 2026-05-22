import CoreAudio

enum EQMode: String, CaseIterable, Identifiable {
    case allSystem
    case selectedApp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .allSystem: return "All Audio"
        case .selectedApp: return "Selected App"
        }
    }
}

enum TapConfiguration: Equatable {
    case global(excludingProcessObjectIDs: [AudioObjectID])
    case processes([AudioObjectID])

    func makeTapDescription(name: String) -> CATapDescription {
        let description: CATapDescription
        switch self {
        case .global(let excluding):
            description = CATapDescription(stereoGlobalTapButExcludeProcesses: excluding)
        case .processes(let processIDs):
            description = CATapDescription(stereoMixdownOfProcesses: processIDs)
        }
        description.name = name
        description.isPrivate = true
        description.muteBehavior = .muted
        return description
    }
}
