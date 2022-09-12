import XCTest
@testable import DarkeyeCore

final class HashLinkTests: TestsBase {
    
    override func asyncSetup() async {
        await super.asyncSetup()
    }
    
    override func asyncTearDown() async {
        await super.asyncTearDown()
    }
    
    func testURL() async {
        await asyncSetup()
        let url = "http://library123.onion"
        var link = Link(url: url, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0)
        await link.save()
        
        if let hashLink: HashLink = await database.value(forKey: HashLink.prefix + link.hash) {
            XCTAssertEqual(hashLink.url, url)
        }
        await asyncTearDown()
    }
    
    func testLink() async {
        await asyncSetup()
        let url = "http://library123.onion"
        let hashLink = HashLink(url: url)
        _ = hashLink.link
        let linkUrl = await hashLink.link().url
        XCTAssertEqual(linkUrl, url)
        await asyncTearDown()
    }
    
    func testLinkWithHash() async {
        await asyncSetup()
        let url = "http://haneinhodfxcjcnsm6efuyzdffcrejd7jmstte7hwdvhf67x6okyb2ad.onion"
        var link = Link(url: url, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0)
        await link.save()
        let rLink = await HashLink.linkWith(hash: link.hash)
        XCTAssertEqual(rLink?.url, url)
        await asyncTearDown()
    }
}
