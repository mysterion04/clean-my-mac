import Foundation
import AppKit

actor AppDetectionService {
    private let fsService = FileSystemService.shared

    func discoverApps() async -> [AppInfo] {
        let searchPaths = [PathConstants.applications, PathConstants.userApplications]
        var apps: [AppInfo] = []

        for dir in searchPaths where FileManager.default.fileExists(atPath: dir.path) {
            let contents = await fsService.contentsOfDirectory(at: dir)
            for url in contents where url.pathExtension == "app" {
                if let info = await buildAppInfo(from: url) {
                    apps.append(info)
                }
            }
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func buildAppInfo(from appURL: URL) async -> AppInfo? {
        guard let bundle = Bundle(url: appURL) else { return nil }

        let bundleID = bundle.bundleIdentifier ?? ""
        let name = (bundle.infoDictionary?["CFBundleName"] as? String)
            ?? (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? appURL.deletingPathExtension().lastPathComponent
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { $0.bundleIdentifier == bundleID }

        let icon = NSWorkspace.shared.icon(forFile: appURL.path)

        var info = AppInfo(
            name: name,
            bundleID: bundleID,
            version: version,
            path: appURL,
            icon: icon,
            isRunning: isRunning
        )

        let appSize = await fsService.sizeOfItem(at: appURL)
        info.appSize = appSize

        let related = await findRelatedFiles(for: info)
        info.relatedFiles = related

        // Compute related file sizes concurrently
        var relatedSize: Int64 = 0
        await withTaskGroup(of: Int64.self) { group in
            for url in related {
                group.addTask {
                    return await self.fsService.sizeOfItem(at: url)
                }
            }
            for await size in group {
                relatedSize += size
            }
        }

        info.relatedFilesSize = relatedSize

        return info
    }

    func findRelatedFiles(for app: AppInfo) async -> [URL] {
        var related: [URL] = []
        let bundleID = app.bundleID
        let name = app.name
        let fm = FileManager.default

        // Helper: add if exists
        func add(_ url: URL) {
            if fm.fileExists(atPath: url.path) {
                related.append(url)
            }
        }

        // ~/Library/Application Support/<name>
        add(PathConstants.userAppSupport.appendingPathComponent(name))

        // ~/Library/Preferences/<bundleID>.plist
        if !bundleID.isEmpty {
            add(PathConstants.userPreferences.appendingPathComponent("\(bundleID).plist"))
        }

        // ~/Library/Caches/<bundleID>
        if !bundleID.isEmpty {
            add(PathConstants.userCaches.appendingPathComponent(bundleID))
        }

        // ~/Library/Logs/<name>
        add(PathConstants.userLogs.appendingPathComponent(name))

        // ~/Library/Saved Application State/<bundleID>.savedState
        if !bundleID.isEmpty {
            add(PathConstants.userSavedState.appendingPathComponent("\(bundleID).savedState"))
        }

        // ~/Library/LaunchAgents/<bundleID>*.plist
        if !bundleID.isEmpty {
            let agents = await fsService.contentsOfDirectory(at: PathConstants.userLaunchAgents)
            for url in agents where url.lastPathComponent.hasPrefix(bundleID) {
                related.append(url)
            }
        }

        // ~/Library/Containers/<bundleID>
        if !bundleID.isEmpty {
            add(PathConstants.userContainers.appendingPathComponent(bundleID))
        }

        // /Library/Application Support/<name>
        add(PathConstants.systemAppSupport.appendingPathComponent(name))

        // /Library/LaunchDaemons/<bundleID>*.plist
        if !bundleID.isEmpty {
            let daemons = await fsService.contentsOfDirectory(at: PathConstants.systemLaunchDaemons)
            for url in daemons where url.lastPathComponent.hasPrefix(bundleID) {
                related.append(url)
            }
        }

        return related
    }
}
