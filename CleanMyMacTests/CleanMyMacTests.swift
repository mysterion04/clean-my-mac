import XCTest
@testable import CleanMyMac

final class CleanMyMacTests: XCTestCase {

    // MARK: - FormattingUtils

    func testFormatBytesKilobytes() {
        let result = FormattingUtils.formatBytes(1024)
        XCTAssertFalse(result.isEmpty)
    }

    func testFormatBytesMegabytes() {
        let result = FormattingUtils.formatBytes(1024 * 1024)
        XCTAssertTrue(result.contains("MB") || result.contains("MiB") || result.contains("megabyte"))
    }

    func testFormatBytesGigabytes() {
        let result = FormattingUtils.formatBytes(1024 * 1024 * 1024)
        XCTAssertTrue(result.contains("GB") || result.contains("GiB") || result.contains("gigabyte"))
    }

    // MARK: - JunkFile model

    func testJunkFileInitialization() {
        let url = URL(fileURLWithPath: "/tmp/test.log")
        let junk = JunkFile(url: url, size: 512, category: .appLogs)
        XCTAssertEqual(junk.name, "test.log")
        XCTAssertEqual(junk.size, 512)
        XCTAssertEqual(junk.category, .appLogs)
        XCTAssertTrue(junk.isSelected)
    }

    // MARK: - FileItem model

    func testFileItemInitialization() {
        let url = URL(fileURLWithPath: "/Users/test/bigfile.mp4")
        let item = FileItem(url: url, size: 200 * 1024 * 1024)
        XCTAssertEqual(item.name, "bigfile.mp4")
        XCTAssertEqual(item.fileExtension, "mp4")
        XCTAssertEqual(item.size, 200 * 1024 * 1024)
        XCTAssertFalse(item.isSelected)
    }

    // MARK: - DiskNode model

    func testDiskNodeFormattedSize() {
        let node = DiskNode(name: "Test", category: .documents, size: 5 * 1024 * 1024 * 1024, children: [])
        XCTAssertFalse(node.formattedSize.isEmpty)
        XCTAssertFalse(node.isEmpty)
    }

    func testDiskNodeEmpty() {
        let node = DiskNode(name: "Empty", category: .other, size: 0, children: [])
        XCTAssertTrue(node.isEmpty)
    }

    // MARK: - PathConstants

    func testPathConstantsHomeExists() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: PathConstants.home.path))
    }

    func testPathConstantsUserCaches() {
        // userCaches should point inside Library
        XCTAssertTrue(PathConstants.userCaches.path.contains("Library/Caches"))
    }

    // MARK: - FileSystemService

    func testFileSystemServiceFileSize() async {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("cmm_test_\(UUID().uuidString).txt")
        let data = Data(repeating: 0x41, count: 1024)
        try? data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let size = await FileSystemService.shared.fileSize(tempURL)
        XCTAssertEqual(size, 1024)
    }

    func testFileSystemServiceExists() async {
        let existing = URL(fileURLWithPath: "/tmp")
        let missing = URL(fileURLWithPath: "/tmp/definitely_does_not_exist_cmm_\(UUID().uuidString)")
        XCTAssertTrue(await FileSystemService.shared.exists(at: existing))
        XCTAssertFalse(await FileSystemService.shared.exists(at: missing))
    }

    func testFileSystemServiceDiskInfo() async {
        let info = await FileSystemService.shared.diskInfo(forPath: "/")
        XCTAssertNotNil(info)
        XCTAssertGreaterThan(info!.totalSpace, 0)
        XCTAssertGreaterThanOrEqual(info!.freeSpace, 0)
        XCTAssertLessThanOrEqual(info!.freeSpace, info!.totalSpace)
    }

    // MARK: - PermissionService

    func testPermissionServiceCheckPermissions() {
        let service = PermissionService.shared
        service.checkPermissions()
        // Just verify it doesn't crash; hasFullDiskAccess will be true or false
        XCTAssertNotNil(service.hasFullDiskAccess)
    }

    // MARK: - JunkCategory

    func testJunkCategorySystemImages() {
        for category in JunkCategory.allCases {
            XCTAssertFalse(category.systemImage.isEmpty)
        }
    }

    // MARK: - DiskCategory

    func testDiskCategoryColors() {
        // Ensure all categories have a color (just verify no crash)
        for category in DiskCategory.allCases {
            _ = category.color
            XCTAssertFalse(category.systemImage.isEmpty)
        }
    }
}
