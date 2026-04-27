import XCTest
@testable import ClearlyCore

final class BookmarkedLocationTests: XCTestCase {

    func testDisplayNameFallsBackToFolderName() {
        let url = URL(fileURLWithPath: "/tmp/App/docs", isDirectory: true)
        let location = BookmarkedLocation(url: url, bookmarkData: Data([1, 2, 3]))

        XCTAssertEqual(location.name, "docs")
        XCTAssertEqual(location.displayName, "docs")
        XCTAssertFalse(location.hasCustomName)
    }

    func testDisplayNameUsesTrimmedCustomName() {
        let url = URL(fileURLWithPath: "/tmp/App/docs", isDirectory: true)
        let location = BookmarkedLocation(
            url: url,
            bookmarkData: Data([1, 2, 3]),
            customName: "  App 1 Docs  \n"
        )

        XCTAssertEqual(location.name, "docs")
        XCTAssertEqual(location.displayName, "App 1 Docs")
        XCTAssertTrue(location.hasCustomName)
    }

    func testBlankCustomNameFallsBackToFolderName() {
        let url = URL(fileURLWithPath: "/tmp/App/docs", isDirectory: true)
        let location = BookmarkedLocation(
            url: url,
            bookmarkData: Data([1, 2, 3]),
            customName: "   "
        )

        XCTAssertEqual(location.displayName, "docs")
        XCTAssertFalse(location.hasCustomName)
    }

    func testStoredBookmarkDecodesLegacyPayloadWithoutCustomName() throws {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "bookmarkData": "AQID"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let bookmark = try JSONDecoder().decode(StoredBookmark.self, from: data)

        XCTAssertEqual(bookmark.id.uuidString, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(bookmark.bookmarkData, Data([1, 2, 3]))
        XCTAssertNil(bookmark.customName)
    }

    func testStoredBookmarkRoundTripsCustomName() throws {
        let original = StoredBookmark(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            bookmarkData: Data([4, 5, 6]),
            customName: "App 2 Docs"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StoredBookmark.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.bookmarkData, original.bookmarkData)
        XCTAssertEqual(decoded.customName, "App 2 Docs")
    }
}
