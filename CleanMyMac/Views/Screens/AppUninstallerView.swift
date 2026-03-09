import SwiftUI

struct AppUninstallerView: View {
    @StateObject private var vm = AppUninstallerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header toolbar
            ToolbarHeader(
                title: "App Uninstaller",
                systemImage: "xmark.circle.fill",
                accentColor: .red,
                statusMessage: vm.statusMessage,
                isLoading: vm.isScanning || vm.isUninstalling,
                primaryLabel: "Scan",
                primaryAction: { vm.scan() },
                destructiveLabel: vm.selectedAppIDs.isEmpty ? nil : "Uninstall \(vm.selectedAppIDs.count)",
                destructiveAction: { vm.requestUninstall() }
            )

            // Search bar
            if !vm.apps.isEmpty {
                SearchBar(text: $vm.searchText, placeholder: "Search applications...")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "111111"))
            }

            Divider().background(Color.white.opacity(0.08))

            // Content
            if vm.apps.isEmpty && !vm.isScanning {
                EmptyStateView(
                    systemImage: "xmark.circle",
                    title: "No Applications Found",
                    subtitle: "Click Scan to discover installed applications.",
                    actionLabel: "Scan Now",
                    action: { vm.scan() }
                )
            } else {
                AppListView(vm: vm)
            }

            // Bottom summary
            if !vm.selectedAppIDs.isEmpty {
                SummaryBar(
                    selectedCount: vm.selectedAppIDs.count,
                    totalSize: vm.totalSelectedSize,
                    color: .red
                )
            }
        }
        .background(Color(hex: "111111"))
        .alert("Confirm Uninstall", isPresented: $vm.showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Uninstall", role: .destructive) { vm.uninstall() }
        } message: {
            Text("Move \(vm.selectedApps.count) app(s) and their data to the Trash? This action can be undone from the Trash.")
        }
        .alert("Success", isPresented: $vm.showSuccess) {
            Button("OK") {}
        } message: {
            Text("Freed \(FormattingUtils.formatBytes(vm.lastCleanedSize)) of disk space.")
        }
        .alert("Error", isPresented: .init(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}

struct AppListView: View {
    @ObservedObject var vm: AppUninstallerViewModel

    var body: some View {
        List {
            // Select All header
            HStack {
                Button(action: {
                    if vm.selectedAppIDs.count == vm.filteredApps.count {
                        vm.deselectAll()
                    } else {
                        vm.selectAll()
                    }
                }) {
                    Label(
                        vm.selectedAppIDs.count == vm.filteredApps.count ? "Deselect All" : "Select All",
                        systemImage: vm.selectedAppIDs.count == vm.filteredApps.count ? "checkmark.circle.fill" : "circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("\(vm.filteredApps.count) apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 4)

            ForEach(vm.filteredApps) { app in
                AppRowView(
                    app: app,
                    isSelected: vm.selectedAppIDs.contains(app.id)
                ) {
                    vm.toggleSelection(app)
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

struct AppRowView: View {
    let app: AppInfo
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            // App icon
            AppIconView(app: app)
                .frame(width: 36, height: 36)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(app.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                    if app.isRunning {
                        Text("Running")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.2)))
                    }
                }
                Text(app.bundleID.isEmpty ? app.path.path : app.bundleID)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Sizes
            VStack(alignment: .trailing, spacing: 2) {
                Text(FormattingUtils.formatBytes(app.totalSize))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                if !app.relatedFiles.isEmpty {
                    Text("+\(app.relatedFiles.count) files")
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

struct AppIconView: View {
    let app: AppInfo

    var body: some View {
        Group {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
