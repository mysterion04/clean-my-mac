import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case uninstaller = "Uninstaller"
    case junkFiles = "Junk Files"
    case diskAnalyzer = "Disk Analyzer"
    case largeFinder = "Large Files"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .uninstaller: return "xmark.circle.fill"
        case .junkFiles: return "trash.fill"
        case .diskAnalyzer: return "internaldrive.fill"
        case .largeFinder: return "arrow.up.right.square.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .dashboard: return .blue
        case .uninstaller: return .red
        case .junkFiles: return .orange
        case .diskAnalyzer: return .purple
        case .largeFinder: return .green
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @EnvironmentObject var permissionService: PermissionService

    var body: some View {
        VStack(spacing: 0) {
            // App header
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("CleanMyMac")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 18)

            Divider()
                .background(Color.white.opacity(0.1))

            // Navigation items
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(SidebarItem.allCases) { item in
                        SidebarRowView(
                            item: item,
                            isSelected: selection == item
                        ) {
                            selection = item
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
            }

            Spacer()

            // FDA status
            Divider()
                .background(Color.white.opacity(0.1))

            FDAStatusView(hasAccess: permissionService.hasFullDiskAccess)
                .padding(12)
        }
        .frame(width: 200)
        .background(Color(hex: "1A1A1A"))
    }
}

struct SidebarRowView: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? item.accentColor : .secondary)
                    .frame(width: 20)

                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : Color(NSColor.secondaryLabelColor))

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FDAStatusView: View {
    let hasAccess: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(hasAccess ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(hasAccess ? "Full Disk Access" : "Limited Access")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
