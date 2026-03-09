import Foundation

actor DiskAnalyzerService {
    private let fsService = FileSystemService.shared

    func analyze() async -> (info: DiskInfo?, nodes: [DiskNode]) {
        let diskInfo = await fsService.diskInfo()

        var nodes: [DiskNode] = []

        await withTaskGroup(of: DiskNode.self) { group in
            group.addTask { await self.sizeNode(.applications, paths: [PathConstants.applications, PathConstants.userApplications]) }
            group.addTask { await self.sizeNode(.system, paths: [URL(fileURLWithPath: "/System"), URL(fileURLWithPath: "/usr"), URL(fileURLWithPath: "/bin")]) }
            group.addTask { await self.sizeNode(.documents, paths: [FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents")]) }
            group.addTask { await self.sizeNode(.media, paths: [
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Movies"),
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Music"),
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Pictures")
            ]) }
            group.addTask { await self.sizeNode(.library, paths: [PathConstants.userLibrary]) }

            for await node in group {
                nodes.append(node)
            }
        }

        let accountedSize = nodes.reduce(0) { $0 + $1.size }
        if let info = diskInfo, info.usedSpace > accountedSize {
            let otherSize = info.usedSpace - accountedSize
            nodes.append(DiskNode(name: "Other", category: .other, size: otherSize, children: []))
        }

        nodes.sort { $0.size > $1.size }
        return (diskInfo, nodes)
    }

    private func sizeNode(_ category: DiskCategory, paths: [URL]) async -> DiskNode {
        var total: Int64 = 0
        for path in paths where FileManager.default.fileExists(atPath: path.path) {
            total += await fsService.directorySizeDeep(path)
        }
        return DiskNode(name: category.rawValue, category: category, size: total, children: [])
    }
}
