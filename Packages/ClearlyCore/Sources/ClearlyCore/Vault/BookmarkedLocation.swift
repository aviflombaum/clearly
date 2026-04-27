import Foundation

/// A user-bookmarked folder location shown in the sidebar.
public struct BookmarkedLocation: Identifiable {
    public let id: UUID
    public let url: URL
    public var bookmarkData: Data
    public var fileTree: [FileNode]
    public var isAccessible: Bool
    public var kind: VaultKind
    public var customName: String?

    public init(
        id: UUID = UUID(),
        url: URL,
        bookmarkData: Data,
        fileTree: [FileNode] = [],
        isAccessible: Bool = false,
        kind: VaultKind = .regular,
        customName: String? = nil
    ) {
        self.id = id
        self.url = url
        self.bookmarkData = bookmarkData
        self.fileTree = fileTree
        self.isAccessible = isAccessible
        self.kind = kind
        self.customName = customName
    }

    public var name: String { url.lastPathComponent }
    public var displayName: String { normalizedCustomName ?? name }
    public var hasCustomName: Bool { normalizedCustomName != nil }

    public var isWiki: Bool { kind.isWiki }

    private var normalizedCustomName: String? {
        guard let customName else { return nil }
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Persistence (Codable wrapper for UserDefaults)

public struct StoredBookmark: Codable {
    public let id: UUID
    public let bookmarkData: Data
    public let customName: String?

    public init(id: UUID, bookmarkData: Data, customName: String? = nil) {
        self.id = id
        self.bookmarkData = bookmarkData
        self.customName = customName
    }

    public init(_ location: BookmarkedLocation) {
        self.id = location.id
        self.bookmarkData = location.bookmarkData
        self.customName = location.customName
    }
}
