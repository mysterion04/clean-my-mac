import Foundation
import SwiftUI

@MainActor
class AppUninstallerViewModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var selectedAppIDs: Set<UUID> = []
    @Published var isScanning = false
    @Published var isUninstalling = false
    @Published var statusMessage = "Click Scan to find installed applications."
    @Published var errorMessage: String?
    @Published var showConfirmation = false
    @Published var showSuccess = false
    @Published var lastCleanedSize: Int64 = 0
    @Published var searchText = ""

    private let detection = AppDetectionService()
    private let uninstaller = AppUninstallerService()
    private var scanTask: Task<Void, Never>?

    var filteredApps: [AppInfo] {
        guard !searchText.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.bundleID.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedApps: [AppInfo] {
        apps.filter { selectedAppIDs.contains($0.id) }
    }

    var totalSelectedSize: Int64 {
        selectedApps.reduce(0) { $0 + $1.totalSize }
    }

    func scan() {
        scanTask?.cancel()
        isScanning = true
        statusMessage = "Scanning applications..."
        apps = []
        selectedAppIDs = []

        scanTask = Task {
            let discovered = await detection.discoverApps()
            guard !Task.isCancelled else { return }
            self.apps = discovered
            self.isScanning = false
            self.statusMessage = "Found \(discovered.count) applications."
        }
    }

    func toggleSelection(_ app: AppInfo) {
        if selectedAppIDs.contains(app.id) {
            selectedAppIDs.remove(app.id)
        } else {
            selectedAppIDs.insert(app.id)
        }
    }

    func selectAll() {
        selectedAppIDs = Set(filteredApps.map { $0.id })
    }

    func deselectAll() {
        selectedAppIDs = []
    }

    func requestUninstall() {
        guard !selectedApps.isEmpty else { return }
        showConfirmation = true
    }

    func uninstall() {
        let toRemove = selectedApps
        isUninstalling = true
        statusMessage = "Uninstalling \(toRemove.count) app(s)..."

        Task { @MainActor in
            var cleaned: Int64 = 0
            for app in toRemove {
                do {
                    try await uninstaller.uninstall(app: app)
                    cleaned += app.totalSize
                    self.apps.removeAll { $0.id == app.id }
                    self.selectedAppIDs.remove(app.id)
                } catch {
                    self.errorMessage = "Failed to uninstall \(app.name): \(error.localizedDescription)"
                }
            }
            self.lastCleanedSize = cleaned
            self.isUninstalling = false
            self.showSuccess = cleaned > 0
            self.statusMessage = cleaned > 0
                ? "Uninstalled \(toRemove.count) app(s). Freed \(FormattingUtils.formatBytes(cleaned))."
                : "Uninstall complete."
        }
    }
}
