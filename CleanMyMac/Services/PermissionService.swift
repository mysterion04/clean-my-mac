import Foundation

@MainActor
class PermissionService: ObservableObject {
    @Published var hasFullDiskAccess: Bool = false

    static let shared = PermissionService()

    private init() {
        checkPermissions()
    }

    func checkPermissions() {
        hasFullDiskAccess = Self.testFullDiskAccess()
    }

    private static func testFullDiskAccess() -> Bool {
        // Try reading paths that require Full Disk Access
        let testPaths = [
            "/Library/Application Support",
            NSHomeDirectory() + "/Library/Mail",
            NSHomeDirectory() + "/Library/Messages"
        ]
        for path in testPaths {
            let url = URL(fileURLWithPath: path)
            if (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) != nil {
                return true
            }
        }
        // Fallback: check if we can read /Library/Caches
        let caches = URL(fileURLWithPath: "/Library/Caches")
        return (try? FileManager.default.contentsOfDirectory(at: caches, includingPropertiesForKeys: nil)) != nil
    }
}
