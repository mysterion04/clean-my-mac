import Foundation

actor LargeFileFinderService {
    private let fsService = FileSystemService.shared

    func scan(
        from rootURL: URL = PathConstants.home,
        sizeThreshold: Int64 = 100 * 1024 * 1024,
        progress: @Sendable @escaping (String) -> Void
    ) async -> [FileItem] {
        progress("Scanning for large files...")

        var results: [FileItem] = []
        let fm = FileManager.default

        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize,
                  Int64(size) >= sizeThreshold else { continue }

            let item = FileItem(url: url, size: Int64(size), modificationDate: values.contentModificationDate)
            results.append(item)
        }

        progress("Found \(results.count) large files")
        return results.sorted { $0.size > $1.size }
    }
}
