import XCTest
@testable import DarkEyeCore

final class LinkAllowedTests: TestsBase {
    
    override func asyncSetup() async {
        await super.asyncSetup()
    }
    
    override func asyncTearDown() async {
        await super.asyncTearDown()
    }
    
    func testAllowedUrl() async {
        await asyncSetup()
        var allowed = Link.allowed(url: "ring://www")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://www.onion/beverages/vodka")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://www.onion/beverages/whiskey")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://2a2a2abbjsjcjwfuozip6idfxsxyowoi3ajqyehqzfqyxezhacur7oyd.onion")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://www.onion/file.zip")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://www.onion/file.jpg")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://www.onion/file.png")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://www.onion/file.mp4")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://www.onion/file.epub")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://www.onion/@file")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://www.onion/file.html")
        XCTAssertTrue(allowed)
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/2022/02/17/richard-ciano-donation-freedom-convoy-canada-givesendgo/?menu=1")
        XCTAssertFalse(allowed)
        await asyncTearDown()
    }
}
