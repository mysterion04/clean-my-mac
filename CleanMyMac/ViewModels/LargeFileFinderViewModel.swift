import Foundation
import SwiftUI

@MainActor
class LargeFileFinderViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var statusMessage = "Click Scan to find large files."
    @Published var errorMessage: String?
    @Published var showConfirmation = false
    @Published var showSuccess = false
    @Published var lastCleanedSize: Int64 = 0
    @Published var scanProgress = ""
    @Published var sizeThresholdMB: Double = 100
    @Published var filterExtension = ""
    @Published var selectedIDs: Set<UUID> = []

    private let finder = LargeFileFinderService()
    private let fsService = FileSystemService.shared
    private var scanTask: Task<Void, Never>?

    var sizeThreshold: Int64 { Int64(sizeThresholdMB) * 1024 * 1024 }

    var filteredFiles: [FileItem] {
        guard !filterExtension.isEmpty else { return files }
        return files.filter { $0.fileExtension == filterExtension.lowercased().trimmingCharacters(in: .init(charactersIn: ".")) }
    }

    var selectedFiles: [FileItem] {
        files.filter { selectedIDs.contains($0.id) }
    }

    var totalSelectedSize: Int64 {
        selectedFiles.reduce(0) { $0 + $1.size }
    }

    var availableExtensions: [String] {
        let exts = Set(files.map { $0.fileExtension }).filter { !$0.isEmpty }
        return exts.sorted()
    }

    func scan() {
        scanTask?.cancel()
        isScanning = true
        files = []
        selectedIDs = []
        statusMessage = "Scanning..."

        let threshold = sizeThreshold
        scanTask = Task { @MainActor in
            let results = await finder.scan(sizeThreshold: threshold) { @MainActor [weak self] message in
                self?.scanProgress = message
            }
            guard !Task.isCancelled else { return }
            files = results
            isScanning = false
            scanProgress = ""
            statusMessage = "Found \(results.count) large files."
        }
    }

    func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func selectAll() {
        selectedIDs = Set(filteredFiles.map { $0.id })
    }

    func deselectAll() {
        selectedIDs = []
    }

    func requestDelete() {
        guard !selectedFiles.isEmpty else { return }
        showConfirmation = true
    }

    func deleteSelected() {
        let toDelete = selectedFiles
        isCleaning = true
        statusMessage = "Moving \(toDelete.count) files to Trash..."

        Task { @MainActor in
            var cleaned: Int64 = 0
            for file in toDelete {
                do {
                    try await fsService.moveToTrash(file.url)
                    cleaned += file.size
                    files.removeAll { $0.id == file.id }
                    selectedIDs.remove(file.id)
                } catch {
                    // continue
                }
            }
            lastCleanedSize = cleaned
            isCleaning = false
            showSuccess = cleaned > 0
            statusMessage = "Moved \(toDelete.count) files to Trash. Freed \(FormattingUtils.formatBytes(cleaned))."
        }
    }
}
