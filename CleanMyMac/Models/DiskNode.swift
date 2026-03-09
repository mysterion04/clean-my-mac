import Foundation
import SwiftUI

enum DiskCategory: String, CaseIterable {
    case applications = "Applications"
    case system = "System"
    case documents = "Documents"
    case media = "Media"
    case library = "Library"
    case other = "Other"

    var color: Color {
        switch self {
        case .applications: return .blue
        case .system: return .orange
        case .documents: return .yellow
        case .media: return .purple
        case .library: return .green
        case .other: return .gray
        }
    }

    var systemImage: String {
        switch self {
        case .applications: return "app.fill"
        case .system: return "gearshape.fill"
        case .documents: return "doc.fill"
        case .media: return "photo.fill"
        case .library: return "books.vertical.fill"
        case .other: return "folder.fill"
        }
    }
}

struct DiskNode: Identifiable {
    let id = UUID()
    let name: String
    let category: DiskCategory
    var size: Int64
    var children: [DiskNode]

    var isEmpty: Bool { size == 0 }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct DiskInfo {
    let totalSpace: Int64
    let freeSpace: Int64
    var usedSpace: Int64 { totalSpace - freeSpace }
    var usagePercentage: Double { Double(usedSpace) / Double(totalSpace) }
}
