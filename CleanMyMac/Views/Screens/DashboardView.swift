import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var permissionService: PermissionService

    let features: [FeatureModel] = [
        FeatureModel(item: .uninstaller, description: "Fully remove apps and all their leftover files."),
        FeatureModel(item: .junkFiles, description: "Clear caches, logs, temp files, and language packs."),
        FeatureModel(item: .diskAnalyzer, description: "Visualize what's consuming your disk space."),
        FeatureModel(item: .largeFinder, description: "Find and delete files larger than 100 MB."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Hero
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CleanMyMac")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                            Text("Keep your Mac clean and fast")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // FDA Warning
                if !permissionService.hasFullDiskAccess {
                    FDAWarningBanner()
                }

                // Feature cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(features) { feature in
                        FeatureCard(item: feature.item, description: feature.description)
                    }
                }
            }
            .padding(24)
        }
        .background(Color(hex: "111111"))
    }
}

struct FeatureModel: Identifiable {
    let id = UUID()
    let item: SidebarItem
    let description: String
}

struct FeatureCard: View {
    let item: SidebarItem
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: item.systemImage)
                    .font(.title2)
                    .foregroundStyle(item.accentColor)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct FDAWarningBanner: View {
    @State private var showInstructions = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Full Disk Access Not Granted")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("Some scans may be limited. Grant access in System Settings → Privacy & Security → Full Disk Access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("How to Grant") {
                showInstructions = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.3), lineWidth: 1))
        )
        .sheet(isPresented: $showInstructions) {
            FDAInstructionsView()
        }
    }
}

struct FDAInstructionsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Grant Full Disk Access")
                .font(.title2.bold())

            Text("To allow CleanMyMac to scan all system files:")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array([
                    "Open System Settings",
                    "Go to Privacy & Security",
                    "Select Full Disk Access",
                    "Click the + button",
                    "Navigate to and select CleanMyMac",
                    "Restart CleanMyMac"
                ].enumerated()), id: \.0) { idx, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.blue))
                        Text(step)
                            .font(.body)
                    }
                }
            }

            Spacer()

            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Dismiss") { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 360, height: 400)
    }
}

