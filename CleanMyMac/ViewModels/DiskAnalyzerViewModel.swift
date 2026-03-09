import Foundation
import SwiftUI

@MainActor
class DiskAnalyzerViewModel: ObservableObject {
    @Published var diskInfo: DiskInfo?
    @Published var categoryNodes: [DiskNode] = []
    @Published var isAnalyzing = false
    @Published var statusMessage = "Click Refresh to analyze disk usage."

    private let analyzer = DiskAnalyzerService()

    func analyze() {
        isAnalyzing = true
        statusMessage = "Analyzing disk usage..."
        categoryNodes = []
        diskInfo = nil

        Task { @MainActor in
            let (info, nodes) = await analyzer.analyze()
            diskInfo = info
            categoryNodes = nodes
            isAnalyzing = false
            if let info = info {
                statusMessage = "\(FormattingUtils.formatBytes(info.usedSpace)) used of \(FormattingUtils.formatBytes(info.totalSpace))"
            } else {
                statusMessage = "Analysis complete."
            }
        }
    }

    var totalAccountedSize: Int64 {
        categoryNodes.reduce(0) { $0 + $1.size }
    }
}
