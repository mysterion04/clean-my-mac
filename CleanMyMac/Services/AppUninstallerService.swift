import Foundation
import AppKit

actor AppUninstallerService {
    private let fsService = FileSystemService.shared

    func uninstall(app: AppInfo) async throws {
        // Terminate the app if running
        if app.isRunning {
            let runningApps = NSWorkspace.shared.runningApplications
            if let runningApp = runningApps.first(where: { $0.bundleIdentifier == app.bundleID }) {
                runningApp.terminate()
                // Give it a moment to close
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms
            }
        }

        var errors: [Error] = []

        // Move main app bundle to trash
        do {
            try await fsService.moveItemsToTrash([app.path])
        } catch {
            errors.append(error)
        }

        // Move related files to trash
        for url in app.relatedFiles {
            do {
                try await fsService.moveItemsToTrash([url])
            } catch {
                errors.append(error)
            }
        }

        if !errors.isEmpty && errors.count == app.relatedFiles.count + 1 {
            throw errors.first!
        }
    }

    func uninstallSelected(apps: [AppInfo]) async throws {
        for app in apps {
            try await uninstall(app: app)
        }
    }
}
