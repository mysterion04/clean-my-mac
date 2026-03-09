import SwiftUI
import Charts

struct DiskAnalyzerView: View {
    @StateObject private var vm = DiskAnalyzerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ToolbarHeader(
                title: "Disk Analyzer",
                systemImage: "internaldrive.fill",
                accentColor: .purple,
                statusMessage: vm.statusMessage,
                isLoading: vm.isAnalyzing,
                primaryLabel: "Refresh",
                primaryAction: { vm.analyze() },
                destructiveLabel: nil,
                destructiveAction: nil
            )

            Divider().background(Color.white.opacity(0.08))

            if vm.categoryNodes.isEmpty && !vm.isAnalyzing {
                EmptyStateView(
                    systemImage: "internaldrive",
                    title: "Disk Not Analyzed",
                    subtitle: "Click Refresh to analyze your disk usage.",
                    actionLabel: "Analyze Now",
                    action: { vm.analyze() }
                )
            } else if vm.isAnalyzing {
                ScanningProgressView(message: "Calculating disk usage...")
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        if let info = vm.diskInfo {
                            DiskOverviewCard(diskInfo: info)
                        }
                        DiskDonutChart(nodes: vm.categoryNodes)
                        DiskBreakdownList(nodes: vm.categoryNodes)
                    }
                    .padding(20)
                }
            }
        }
        .background(Color(hex: "111111"))
        .onAppear { if vm.categoryNodes.isEmpty { vm.analyze() } }
    }
}

struct DiskOverviewCard: View {
    let diskInfo: DiskInfo

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Disk Overview")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(diskInfo.usagePercentage * 100))% used")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Usage bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(diskInfo.usagePercentage > 0.9 ? Color.red : diskInfo.usagePercentage > 0.75 ? Color.orange : Color.blue)
                        .frame(width: geo.size.width * diskInfo.usagePercentage, height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                DiskStatLabel(label: "Total", value: FormattingUtils.formatBytes(diskInfo.totalSpace), color: .secondary)
                Spacer()
                DiskStatLabel(label: "Used", value: FormattingUtils.formatBytes(diskInfo.usedSpace), color: .white)
                Spacer()
                DiskStatLabel(label: "Free", value: FormattingUtils.formatBytes(diskInfo.freeSpace), color: .green)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct DiskStatLabel: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct DiskDonutChart: View {
    let nodes: [DiskNode]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Space by Category")
                .font(.headline)
                .foregroundStyle(.white)

            Chart(nodes, id: \.id) { node in
                SectorMark(
                    angle: .value("Size", node.size),
                    innerRadius: .ratio(0.55),
                    angularInset: 2
                )
                .foregroundStyle(node.category.color)
                .cornerRadius(4)
            }
            .frame(height: 220)
            .chartLegend(.hidden)

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(nodes, id: \.id) { node in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(node.category.color)
                            .frame(width: 8, height: 8)
                        Text(node.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(FormattingUtils.formatBytes(node.size))
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }
}

struct DiskBreakdownList: View {
    let nodes: [DiskNode]

    var total: Int64 { nodes.reduce(0) { $0 + $1.size } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                ForEach(nodes, id: \.id) { node in
                    DiskBarRow(node: node, maxSize: nodes.first?.size ?? 1)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }
}

struct DiskBarRow: View {
    let node: DiskNode
    let maxSize: Int64

    var fraction: Double { maxSize > 0 ? Double(node.size) / Double(maxSize) : 0 }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: node.category.systemImage)
                    .font(.system(size: 12))
                    .foregroundStyle(node.category.color)
                    .frame(width: 16)
                Text(node.name)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                Spacer()
                Text(FormattingUtils.formatBytes(node.size))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(node.category.color.opacity(0.8))
                        .frame(width: geo.size.width * fraction, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
