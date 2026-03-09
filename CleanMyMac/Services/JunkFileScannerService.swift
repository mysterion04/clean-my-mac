import Foundation

actor JunkFileScannerService {
    private let fsService = FileSystemService.shared

    func scan(progress: @escaping @Sendable (String) -> Void) async -> [JunkFile] {
        var results: [JunkFile] = []

        await withTaskGroup(of: [JunkFile].self) { group in
            group.addTask { await self.scanSystemCaches(progress: progress) }
            group.addTask { await self.scanAppLogs(progress: progress) }
            group.addTask { await self.scanTempFiles(progress: progress) }
            group.addTask { await self.scanBrokenDownloads(progress: progress) }
            group.addTask { await self.scanLanguagePacks(progress: progress) }
            group.addTask { await self.scanDeveloperJunk(progress: progress) }

            for await partial in group {
                results.append(contentsOf: partial)
            }
        }

        return results.sorted { $0.size > $1.size }
    }

    private func scanSystemCaches(progress: @Sendable @escaping (String) -> Void) async -> [JunkFile] {
        progress("Scanning system caches...")
        var items: [JunkFile] = []

        let cacheDirs = [PathConstants.userCaches, PathConstants.systemCaches]
        for dir in cacheDirs {
            let contents = await fsService.contentsOfDirectory(at: dir)
            for url in contents {
                let size = await fsService.sizeOfItem(at: url)
                if size > 0 {
                    items.append(JunkFile(url: url, size: size, category: .systemCaches))
                }
            }
        }
        return items
    }

    private func scanAppLogs(progress: @Sendable @escaping (String) -> Void) async -> [JunkFile] {
        progress("Scanning app logs...")
        var items: [JunkFile] = []

        let logDirs = [PathConstants.userLogs, PathConstants.systemLogs]
        for dir in logDirs {
            let contents = await fsService.contentsOfDirectory(at: dir)
            for url in contents {
                let size = await fsService.sizeOfItem(at: url)
                if size > 0 {
                    items.append(JunkFile(url: url, size: size, category: .appLogs))
                }
            }
        }
        return items
    }

    private func scanTempFiles(progress: @Sendable @escaping (String) -> Void) async -> [JunkFile] {
        progress("Scanning temp files...")
        var items: [JunkFile] = []
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let fm = FileManager.default

        let tempDirs = [PathConstants.tmp, PathConstants.varTmp]
        for dir in tempDirs {
            guard fm.fileExists(atPath: dir.path) else { continue }
            let contents = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
            for url in contents {
                let attrs = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                let modDate = attrs?.contentModificationDate ?? Date.distantPast
                if modDate < thirtyDaysAgo {
                    let size = await fsService.sizeOfItem(at: url)
                    if size > 0 {
                        items.append(JunkFile(url: url, size: size, category: .tempFiles))
                    }
                }
            }
        }
        return items
    }

    private func scanBrokenDownloads(progress: @Sendable @escaping (String) -> Void) async -> [JunkFile] {
        progress("Scanning broken downloads...")
        var items: [JunkFile] = []
        let fm = FileManager.default

        guard fm.fileExists(atPath: PathConstants.downloads.path) else { return [] }
        let contents = (try? fm.contentsOfDirectory(at: PathConstants.downloads, includingPropertiesForKeys: [.fileSizeKey])) ?? []

        for url in contents {
            let ext = url.pathExtension.lowercased()
            if PathConstants.brokenDownloadExtensions.contains(ext) {
                let size = await fsService.fileSize(url)
                items.append(JunkFile(url: url, size: size, category: .brokenDownloads))
            }
        }
        return items
    }

    private func scanLanguagePacks(progress: @Sendable @escaping (String) -> Void) async -> [JunkFile] {
        progress("Scanning language packs...")
        var items: [JunkFile] = []

        let preferredLanguages = Set(Locale.preferredLanguages.compactMap { lang -> String? in
            let parts = lang.components(separatedBy: "-")
            return parts.first
        })

        let appDirs = await fsService.contentsOfDirectory(at: PathConstants.applications)

        for appURL in appDirs where appURL.pathExtension == "app" {
            let resourcesURL = appURL.appendingPathComponent("Contents/Resources")
            let lprojDirs = await fsService.contentsOfDirectory(at: resourcesURL)

            for lproj in lprojDirs where lproj.pathExtension == "lproj" {
                let langCode = lproj.deletingPathExtension().lastPathComponent
                let normalized = langCode.components(separatedBy: "_").first ?? langCode
                if !preferredLanguages.contains(normalized) && normalized != "Base" && normalized != "en" {
                    let size = await fsService.sizeOfItem(at: lproj)
                    if size > 0 {
                        items.append(JunkFile(url: lproj, size: size, category: .languagePacks))
                    }
                }
            }
        }
        return items
    }

    private func scanDeveloperJunk(progress: @Sendable @escaping (String) -> Void) async -> [JunkFile] {
        progress("Scanning developer junk...")
        var items: [JunkFile] = []
        let fm = FileManager.default

        // Xcode DerivedData
        if fm.fileExists(atPath: PathConstants.xcodeDerivedData.path) {
            let contents = await fsService.contentsOfDirectory(at: PathConstants.xcodeDerivedData)
            for url in contents {
                let size = await fsService.sizeOfItem(at: url)
                if size > 0 {
                    items.append(JunkFile(url: url, size: size, category: .developerJunk))
                }
            }
        }

        // npm cache
        if fm.fileExists(atPath: PathConstants.npmCache.path) {
            let size = await fsService.sizeOfItem(at: PathConstants.npmCache)
            if size > 0 {
                items.append(JunkFile(url: PathConstants.npmCache, size: size, category: .developerJunk))
            }
        }

        // CocoaPods cache
        if fm.fileExists(atPath: PathConstants.cocoaPodsCache.path) {
            let size = await fsService.sizeOfItem(at: PathConstants.cocoaPodsCache)
            if size > 0 {
                items.append(JunkFile(url: PathConstants.cocoaPodsCache, size: size, category: .developerJunk))
            }
        }

        return items
    }
}
