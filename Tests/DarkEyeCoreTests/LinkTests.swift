import XCTest
@testable import DarkEyeCore

final class LinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let packageRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "DarkEyeCoreTests/LinkTests.swift", with: "/")).path
        database = Database(parentPath: packageRoot + "Library", name: "Database")
    }
    
    override func tearDown() {
        super.tearDown()
        database.deleteDatabaseFromDisk()
    }
    
    func testFirstKey() {
        database["link-http://hanein.news"] = Link(url: "http://hanein.news")
        XCTAssertEqual(Link.firstKey, "link-http://hanein.news")
    }
}
