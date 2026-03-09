import Foundation

enum PathConstants {
    static let home = FileManager.default.homeDirectoryForCurrentUser

    // Applications
    static let applications = URL(fileURLWithPath: "/Applications")
    static let userApplications = home.appendingPathComponent("Applications")

    // User Library
    static let userLibrary = home.appendingPathComponent("Library")
    static let userCaches = userLibrary.appendingPathComponent("Caches")
    static let userLogs = userLibrary.appendingPathComponent("Logs")
    static let userPreferences = userLibrary.appendingPathComponent("Preferences")
    static let userAppSupport = userLibrary.appendingPathComponent("Application Support")
    static let userSavedState = userLibrary.appendingPathComponent("Saved Application State")
    static let userLaunchAgents = userLibrary.appendingPathComponent("LaunchAgents")
    static let userContainers = userLibrary.appendingPathComponent("Containers")
    static let userGroupContainers = userLibrary.appendingPathComponent("Group Containers")

    // System Library
    static let systemLibrary = URL(fileURLWithPath: "/Library")
    static let systemCaches = systemLibrary.appendingPathComponent("Caches")
    static let systemLogs = systemLibrary.appendingPathComponent("Logs")
    static let systemAppSupport = systemLibrary.appendingPathComponent("Application Support")
    static let systemLaunchDaemons = URL(fileURLWithPath: "/Library/LaunchDaemons")

    // Temp
    static let tmp = URL(fileURLWithPath: "/tmp")
    static let varTmp = URL(fileURLWithPath: "/var/tmp")

    // Downloads
    static let downloads = home.appendingPathComponent("Downloads")

    // Developer
    static let xcodeDevData = home.appendingPathComponent("Library/Developer/Xcode")
    static let xcodeDerivedData = xcodeDevData.appendingPathComponent("DerivedData")
    static let xcodeArchives = xcodeDevData.appendingPathComponent("Archives")
    static let xcodeSimulators = xcodeDevData.appendingPathComponent("CoreSimulator/Devices")
    static let npmCache = home.appendingPathComponent(".npm")
    static let cocoaPodsCache = home.appendingPathComponent("Library/Caches/CocoaPods")
    static let swiftPMCache = home.appendingPathComponent("Library/Caches/org.swift.swiftpm")

    // Protected paths to test FDA
    static let fdaTestPath = URL(fileURLWithPath: "/Library/Application Support")

    static let brokenDownloadExtensions: Set<String> = ["partial", "download", "tmp", "crdownload", "opdownload"]
}
