import Foundation
import AppKit

// @unchecked Sendable because NSImage is a class; icon is set once at construction and never mutated.
struct AppInfo: Identifiable, Hashable, @unchecked Sendable {
    let id: UUID
    let name: String
    let bundleID: String
    let version: String
    let path: URL
    let icon: NSImage?
    var isRunning: Bool
    var relatedFiles: [URL]
    var appSize: Int64
    var relatedFilesSize: Int64

    init(
        id: UUID = UUID(),
        name: String,
        bundleID: String,
        version: String,
        path: URL,
        icon: NSImage? = nil,
        isRunning: Bool = false,
        relatedFiles: [URL] = [],
        appSize: Int64 = 0,
        relatedFilesSize: Int64 = 0
    ) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.version = version
        self.path = path
        self.icon = icon
        self.isRunning = isRunning
        self.relatedFiles = relatedFiles
        self.appSize = appSize
        self.relatedFilesSize = relatedFilesSize
    }

    var totalSize: Int64 {
        appSize + relatedFilesSize
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }
}
