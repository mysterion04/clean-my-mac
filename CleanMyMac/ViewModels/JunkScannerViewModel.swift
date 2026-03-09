import Foundation
import SwiftUI

@MainActor
class JunkScannerViewModel: ObservableObject {
    @Published var junkFiles: [JunkFile] = []
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var statusMessage = "Click Scan to find junk files."
    @Published var errorMessage: String?
    @Published var showConfirmation = false
    @Published var showSuccess = false
    @Published var lastCleanedSize: Int64 = 0
    @Published var scanProgress = ""

    private let scanner = JunkFileScannerService()
    private let fsService = FileSystemService.shared
    private var scanTask: Task<Void, Never>?

    var groupedByCategory: [JunkCategory: [JunkFile]] {
        Dictionary(grouping: junkFiles, by: { $0.category })
    }

    var selectedFiles: [JunkFile] {
        junkFiles.filter { $0.isSelected }
    }

    var totalSize: Int64 {
        junkFiles.reduce(0) { $0 + $1.size }
    }

    var selectedSize: Int64 {
        selectedFiles.reduce(0) { $0 + $1.size }
    }

    func scan() {
        scanTask?.cancel()
        isScanning = true
        junkFiles = []
        statusMessage = "Scanning..."
        scanProgress = ""

        scanTask = Task {
            let results = await scanner.scan { [weak self] message in
                Task { @MainActor [weak self] in
                    self?.scanProgress = message
                }
            }
            guard !Task.isCancelled else { return }
            self.junkFiles = results
            self.isScanning = false
            self.statusMessage = "Found \(results.count) items (\(FormattingUtils.formatBytes(self.totalSize)))."
            self.scanProgress = ""
        }
    }

    func toggleSelection(id: UUID) {
        if let idx = junkFiles.firstIndex(where: { $0.id == id }) {
            junkFiles[idx].isSelected.toggle()
        }
    }

    func selectAll() {
        for i in junkFiles.indices { junkFiles[i].isSelected = true }
    }

    func deselectAll() {
        for i in junkFiles.indices { junkFiles[i].isSelected = false }
    }

    func selectCategory(_ category: JunkCategory) {
        for i in junkFiles.indices where junkFiles[i].category == category {
            junkFiles[i].isSelected = true
        }
    }

    func requestClean() {
        guard !selectedFiles.isEmpty else { return }
        showConfirmation = true
    }

    func clean() {
        let toClean = selectedFiles
        isCleaning = true
        statusMessage = "Cleaning \(toClean.count) items..."

        Task { @MainActor in
            var cleaned: Int64 = 0
            for file in toClean {
                do {
                    try await fsService.moveToTrash(file.url)
                    cleaned += file.size
                    self.junkFiles.removeAll { $0.id == file.id }
                } catch {
                    // Some files may already be gone; continue
                }
            }
            self.lastCleanedSize = cleaned
            self.isCleaning = false
            self.showSuccess = cleaned > 0
            self.statusMessage = "Cleaned \(toClean.count) items. Freed \(FormattingUtils.formatBytes(cleaned))."
        }
    }
}
