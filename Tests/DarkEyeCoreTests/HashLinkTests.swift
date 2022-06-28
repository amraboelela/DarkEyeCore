import XCTest
@testable import DarkEyeCore

final class HashLinkTests: TestsBase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testURL() {
        let url = "http://library123.onion"
        var link = Link(url: url, hash: "", lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, numberOfReports: 0, blocked: true, html: "<html><body><p>I went to college to go to the library</p></body></html>")
        link.save()
        
        if let hashLink: HashLink = database[HashLink.prefix + link.hash] {
            XCTAssertEqual(hashLink.url, url)
        }
    }
    
    func testLink() {
        let url = "http://library123.onion"
        let hashLink = HashLink(url: url)
        var link = hashLink.link
        link.load()
        XCTAssertNotNil(link.html)
        XCTAssertEqual(hashLink.link.url, url)
    }
    
    func testLinkWithHash() throws {
        let url = "http://library123.onion"
        var link = Link(url: url, hash: "", lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, numberOfReports: 0, blocked: true, html: "<html><body><p>I went to college to go to the library</p></body></html>")
        link.save()
        let rLink = try XCTUnwrap(HashLink.linkWith(hash: link.hash))
        XCTAssertEqual(rLink.url, url)
    }
}
