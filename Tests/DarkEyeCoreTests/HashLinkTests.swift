import XCTest
@testable import DarkEyeCore

final class HashLinkTests: TestsBase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testURL() async {
        let url = "http://library123.onion"
        var link = Link(url: url, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, numberOfReports: 0, blocked: true)
        await link.save()
        
        if let hashLink: HashLink = await database.valueForKey(HashLink.prefix + link.hash) {
            XCTAssertEqual(hashLink.url, url)
        }
    }
    
    func testLink() async {
        let url = "http://library123.onion"
        let hashLink = HashLink(url: url)
        _ = hashLink.link
        let linkUrl = await hashLink.link().url
        XCTAssertEqual(linkUrl, url)
    }
    
    func testLinkWithHash() async {
        let url = "http://library123.onion"
        var link = Link(url: url, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, numberOfReports: 0, blocked: true)
        await link.save()
        let rLink = await HashLink.linkWith(hash: link.hash)
        XCTAssertEqual(rLink?.url, url)
    }
}
