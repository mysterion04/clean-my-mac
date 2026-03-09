import SwiftUI

struct LargeFileFinderView: View {
    @StateObject private var vm = LargeFileFinderViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ToolbarHeader(
                title: "Large File Finder",
                systemImage: "arrow.up.right.square.fill",
                accentColor: .green,
                statusMessage: vm.isScanning ? vm.scanProgress : vm.statusMessage,
                isLoading: vm.isScanning || vm.isCleaning,
                primaryLabel: "Scan",
                primaryAction: { vm.scan() },
                destructiveLabel: vm.selectedIDs.isEmpty ? nil : "Delete \(vm.selectedIDs.count)",
                destructiveAction: { vm.requestDelete() }
            )

            // Threshold control
            ThresholdControl(thresholdMB: $vm.sizeThresholdMB)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "111111"))

            Divider().background(Color.white.opacity(0.08))

            if vm.files.isEmpty && !vm.isScanning {
                EmptyStateView(
                    systemImage: "arrow.up.right.square",
                    title: "No Large Files Found",
                    subtitle: "Click Scan to find files larger than \(Int(vm.sizeThresholdMB)) MB.",
                    actionLabel: "Scan Now",
                    action: { vm.scan() }
                )
            } else if vm.isScanning && vm.files.isEmpty {
                ScanningProgressView(message: vm.scanProgress)
            } else {
                LargeFileListView(vm: vm)
            }

            if !vm.selectedIDs.isEmpty {
                SummaryBar(
                    selectedCount: vm.selectedIDs.count,
                    totalSize: vm.totalSelectedSize,
                    color: .green
                )
            }
        }
        .background(Color(hex: "111111"))
        .alert("Confirm Delete", isPresented: $vm.showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Move to Trash", role: .destructive) { vm.deleteSelected() }
        } message: {
            Text("Move \(vm.selectedFiles.count) file(s) to the Trash? (\(FormattingUtils.formatBytes(vm.totalSelectedSize)))")
        }
        .alert("Done", isPresented: $vm.showSuccess) {
            Button("OK") {}
        } message: {
            Text("Freed \(FormattingUtils.formatBytes(vm.lastCleanedSize)) of disk space.")
        }
    }
}

struct ThresholdControl: View {
    @Binding var thresholdMB: Double

    var body: some View {
        HStack(spacing: 12) {
            Text("Min size:")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Slider(value: $thresholdMB, in: 10...2048, step: 10)
                .frame(width: 160)
                .tint(.green)

            Text("\(Int(thresholdMB)) MB")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 60)
        }
    }
}

struct LargeFileListView: View {
    @ObservedObject var vm: LargeFileFinderViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Extension filter
            if !vm.availableExtensions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isActive: vm.filterExtension.isEmpty) {
                            vm.filterExtension = ""
                        }
                        ForEach(vm.availableExtensions, id: \.self) { ext in
                            FilterChip(label: ".\(ext)", isActive: vm.filterExtension == ext) {
                                vm.filterExtension = vm.filterExtension == ext ? "" : ext
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(hex: "111111"))
            }

            List {
                HStack {
                    Button(action: {
                        if vm.selectedIDs.count == vm.filteredFiles.count {
                            vm.deselectAll()
                        } else {
                            vm.selectAll()
                        }
                    }) {
                        Label(
                            vm.selectedIDs.count == vm.filteredFiles.count ? "Deselect All" : "Select All",
                            systemImage: vm.selectedIDs.count == vm.filteredFiles.count ? "checkmark.circle.fill" : "circle"
                        )
                        .font(.caption)
                        .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("\(vm.filteredFiles.count) files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                ForEach(vm.filteredFiles) { file in
                    LargeFileRowView(
                        file: file,
                        isSelected: vm.selectedIDs.contains(file.id)
                    ) {
                        vm.toggleSelection(file.id)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(hex: "111111"))
        }
    }
}

struct FilterChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? .black : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(isActive ? Color.green : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }
}

struct LargeFileRowView: View {
    let file: FileItem
    let isSelected: Bool
    let onToggle: () -> Void

    var fileIcon: String {
        switch file.fileExtension {
        case "mp4", "mov", "avi", "mkv": return "film.fill"
        case "mp3", "wav", "aac", "flac": return "music.note"
        case "zip", "tar", "gz", "dmg", "pkg": return "archivebox.fill"
        case "pdf": return "doc.richtext.fill"
        case "jpg", "jpeg", "png", "heic", "raw": return "photo.fill"
        case "app": return "app.fill"
        default: return "doc.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: fileIcon)
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(file.url.deletingLastPathComponent().path)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(FormattingUtils.formatBytes(file.size))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                if let date = file.modificationDate {
                    Text(FormattingUtils.formatDate(date))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}
