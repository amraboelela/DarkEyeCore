import XCTest
@testable import DarkEyeCore

final class LinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let testRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "DarkEyeCoreTests/LinkTests.swift", with: "/")).path
        database = Database(parentPath: testRoot + "Library", name: "Database")
    }
    
    override func tearDown() {
        super.tearDown()
        database.deleteDatabaseFromDisk()
    }
    
    func testFirstKey() {
        database["link-http://hanein1.news"] = Link(url: "http://hanein1.news")
        database["link-http://hanein2.news"] = Link(url: "http://hanein2.news")
        database["link-http://hanein3.news"] = Link(url: "http://hanein3.news")
        XCTAssertEqual(Link.firstKey, "link-http://hanein1.news")
    }
    
    func testKey() {
        let link = Link(url: "http://hanein1.news")
        XCTAssertEqual(link.key, "link-http://hanein1.news")
    }
    
    func testWithUrl() {
        let link = Link.with(url: "http://hanein1.news")
        XCTAssertEqual(link.url, "http://hanein1.news")
    }
    
    func testFromKey() {
        let link = Link.from(key: "link-http://hanein1.news")
        XCTAssertEqual(link.url, "http://hanein1.news")
    }
    
    func testLinks() {
        let links = Link.links(withSearchText: "wiki", count: 20)
        XCTAssertEqual(links.count, 0)
    }
    
    func testSave() {
        var link = Link(url: "http://hanein1.news")
        var saved = link.save()
        XCTAssertTrue(saved)
        XCTAssertEqual(Link.firstKey, "link-http://hanein1.news")
        link = Link(url: "http://hanein2.news")
        saved = link.save()
        XCTAssertTrue(saved)
        link = Link(url: "http://hanein1.news")
        saved = link.save()
        XCTAssertFalse(saved)
    }
    
    func testProcess() {
        var link = Link(url: "http://hanein1.news")
        XCTAssertEqual(link.lastProcessTime, 0)
        link.process()
        XCTAssertNotEqual(link.lastProcessTime, 0)
    }
    
    func testUrlFromKey() {
        let url = Link.url(fromKey: "link-http://hanein1.news")
        XCTAssertEqual(url, "http://hanein1.news")
    }
    
}
