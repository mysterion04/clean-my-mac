import SwiftUI

@main
struct CleanMyMacApp: App {
    @StateObject private var permissionService = PermissionService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(permissionService)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
