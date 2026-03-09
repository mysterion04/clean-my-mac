import SwiftUI

struct MainView: View {
    @State private var selection: SidebarItem? = .dashboard

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $selection)

            Divider()
                .background(Color.white.opacity(0.1))

            // Detail pane
            Group {
                switch selection {
                case .dashboard, .none:
                    DashboardView()
                case .uninstaller:
                    AppUninstallerView()
                case .junkFiles:
                    JunkScannerView()
                case .diskAnalyzer:
                    DiskAnalyzerView()
                case .largeFinder:
                    LargeFileFinderView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "111111"))
    }
}
