import Foundation

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let modificationDate: Date?
    let fileExtension: String
    var isSelected: Bool = false

    init(url: URL, size: Int64, modificationDate: Date? = nil) {
        self.url = url
        self.name = url.lastPathComponent
        self.size = size
        self.modificationDate = modificationDate
        self.fileExtension = url.pathExtension.lowercased()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }
}
