import Foundation

actor FileSystemService {
    static let shared = FileSystemService()
    private let fm = FileManager.default

    // MARK: - Size calculation

    func sizeOfItem(at url: URL) -> Int64 {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        if isDir.boolValue {
            return directorySize(url)
        } else {
            return fileSize(url)
        }
    }

    func fileSize(_ url: URL) -> Int64 {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0
    }

    func directorySize(_ url: URL) -> Int64 {
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize else { continue }
            total += Int64(size)
        }
        return total
    }

    func directorySizeDeep(_ url: URL) -> Int64 {
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize else { continue }
            total += Int64(size)
        }
        return total
    }

    // MARK: - Directory listing

    func contentsOfDirectory(at url: URL) -> [URL] {
        (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
    }

    func contentsOfDirectoryIncludingHidden(at url: URL) -> [URL] {
        (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])) ?? []
    }

    // MARK: - File operations

    func moveToTrash(_ url: URL) throws {
        try fm.trashItem(at: url, resultingItemURL: nil)
    }

    func moveItemsToTrash(_ urls: [URL]) async throws {
        for url in urls {
            try moveToTrash(url)
        }
    }

    func exists(at url: URL) -> Bool {
        fm.fileExists(atPath: url.path)
    }

    func isDirectory(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        fm.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }

    // MARK: - Disk info

    func diskInfo(forPath path: String = "/") -> DiskInfo? {
        guard let attrs = try? fm.attributesOfFileSystem(forPath: path) else { return nil }
        guard let total = attrs[.systemSize] as? Int64,
              let free = attrs[.systemFreeSize] as? Int64 else { return nil }
        return DiskInfo(totalSpace: total, freeSpace: free)
    }

    // MARK: - Glob matching

    func contentsMatching(in directory: URL, predicate: (URL) -> Bool) -> [URL] {
        contentsOfDirectory(at: directory).filter(predicate)
    }

    func enumerateFiles(
        at url: URL,
        options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles],
        handler: (URL, inout Bool) -> Void
    ) {
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .isDirectoryKey, .contentModificationDateKey],
            options: options
        ) else { return }

        var stop = false
        for case let fileURL as URL in enumerator {
            handler(fileURL, &stop)
            if stop { break }
        }
    }
}
