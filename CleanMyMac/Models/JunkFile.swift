import Foundation

enum JunkCategory: String, CaseIterable, Sendable {
    case systemCaches = "System Caches"
    case appLogs = "App Logs"
    case tempFiles = "Temp Files"
    case brokenDownloads = "Broken Downloads"
    case languagePacks = "Language Packs"
    case developerJunk = "Developer Junk"

    var systemImage: String {
        switch self {
        case .systemCaches: return "memorychip"
        case .appLogs: return "doc.text"
        case .tempFiles: return "clock.arrow.circlepath"
        case .brokenDownloads: return "arrow.down.circle.dotted"
        case .languagePacks: return "globe"
        case .developerJunk: return "hammer"
        }
    }
}

struct JunkFile: Identifiable, Hashable, Sendable {
    let id: UUID
    let url: URL
    let name: String
    let size: Int64
    let category: JunkCategory
    var isSelected: Bool = true

    init(url: URL, size: Int64, category: JunkCategory) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.size = size
        self.category = category
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: JunkFile, rhs: JunkFile) -> Bool {
        lhs.id == rhs.id
    }
}
