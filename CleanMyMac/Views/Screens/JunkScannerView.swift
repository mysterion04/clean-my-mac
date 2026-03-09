import SwiftUI

struct JunkScannerView: View {
    @StateObject private var vm = JunkScannerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ToolbarHeader(
                title: "Junk File Scanner",
                systemImage: "trash.fill",
                accentColor: .orange,
                statusMessage: vm.isScanning ? vm.scanProgress : vm.statusMessage,
                isLoading: vm.isScanning || vm.isCleaning,
                primaryLabel: "Scan",
                primaryAction: { vm.scan() },
                destructiveLabel: vm.selectedFiles.isEmpty ? nil : "Clean \(vm.selectedFiles.count)",
                destructiveAction: { vm.requestClean() }
            )

            Divider().background(Color.white.opacity(0.08))

            if vm.junkFiles.isEmpty && !vm.isScanning {
                EmptyStateView(
                    systemImage: "trash",
                    title: "No Junk Files Found",
                    subtitle: "Click Scan to search for caches, logs, and temp files.",
                    actionLabel: "Scan Now",
                    action: { vm.scan() }
                )
            } else if vm.isScanning && vm.junkFiles.isEmpty {
                ScanningProgressView(message: vm.scanProgress)
            } else {
                JunkListView(vm: vm)
            }

            if !vm.selectedFiles.isEmpty {
                SummaryBar(
                    selectedCount: vm.selectedFiles.count,
                    totalSize: vm.selectedSize,
                    color: .orange
                )
            }
        }
        .background(Color(hex: "111111"))
        .alert("Confirm Clean", isPresented: $vm.showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clean", role: .destructive) { vm.clean() }
        } message: {
            Text("Move \(vm.selectedFiles.count) item(s) to the Trash? (\(FormattingUtils.formatBytes(vm.selectedSize)))")
        }
        .alert("Cleaning Complete", isPresented: $vm.showSuccess) {
            Button("OK") {}
        } message: {
            Text("Freed \(FormattingUtils.formatBytes(vm.lastCleanedSize)) of disk space.")
        }
    }
}

struct JunkListView: View {
    @ObservedObject var vm: JunkScannerViewModel

    var body: some View {
        List {
            ForEach(JunkCategory.allCases, id: \.self) { category in
                if let items = vm.groupedByCategory[category], !items.isEmpty {
                    Section {
                        ForEach(items) { item in
                            JunkFileRowView(
                                file: item,
                                isSelected: item.isSelected
                            ) {
                                vm.toggleSelection(id: item.id)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        JunkCategoryHeader(
                            category: category,
                            count: items.count,
                            size: items.reduce(0) { $0 + $1.size },
                            onSelectAll: { vm.selectCategory(category) }
                        )
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(hex: "111111"))
    }
}

struct JunkCategoryHeader: View {
    let category: JunkCategory
    let count: Int
    let size: Int64
    let onSelectAll: () -> Void

    var body: some View {
        HStack {
            Image(systemName: category.systemImage)
                .font(.system(size: 12))
                .foregroundStyle(.orange)
            Text(category.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            Text("(\(count) items)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(FormattingUtils.formatBytes(size))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Button("Select All") { onSelectAll() }
                .buttonStyle(.plain)
                .font(.system(size: 10))
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .listRowBackground(Color.white.opacity(0.04))
    }
}

struct JunkFileRowView: View {
    let file: JunkFile
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? .orange : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: "doc.fill")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(file.url.deletingLastPathComponent().path)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(FormattingUtils.formatBytes(file.size))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}
