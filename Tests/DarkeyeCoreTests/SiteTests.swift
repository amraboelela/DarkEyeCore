import XCTest
@testable import DarkeyeCore

final class SiteTests: TestsBase {
    
    override func asyncSetup() async {
        await super.asyncSetup()
    }
    
    override func asyncTearDown() async {
        await super.asyncTearDown()
    }
    
    func testFirstKey() async {
        await asyncSetup()
        try? await database.setValue(
            Site(url: "http://hanein1.onion"),
            forKey: "site-hanein1"
        )
        try? await database.setValue(
            Site(url: "http://hanein2.onion"),
            forKey: "site-hanein2"
        )
        try? await database.setValue(
            Site(url: "http://hanein3.onion"),
            forKey: "site-hanein3"
        )
        let firstKey = await Site.firstKey()
        XCTAssertEqual(firstKey, "site-hanein1")
        await asyncTearDown()
    }
    
    func testKey() async {
        await asyncSetup()
        let site = Site(url: "http://hanein1.onion")
        XCTAssertEqual(site.key, "site-hanein1")
        await asyncTearDown()
    }
    
    func testCanBeBlocked() async {
        await asyncSetup()
        var site = Site(url: "http://hanein1.onion")
        XCTAssertTrue(site.canBeBlocked)
        let url = "http://5wvugn3zqfbianszhldcqz2u7ulj3xex6i3ha3c5znpgdcnqzn24nnid.onion"
        site = Site(url: url)
        XCTAssertFalse(site.canBeBlocked)
        await asyncTearDown()
    }
    
    func testAllowed() async {
        await asyncSetup()
        var site = Site(url: "http://2a2a2abbjsjcjwfuozip6idfxsxyowoi3ajqyehqzfqyxezhacur7oyd.onion")
        XCTAssertFalse(site.allowed)
        site = Site(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion")
        XCTAssertTrue(site.allowed)
        site = Site(url: "http://27m3p2uv7igmj6kvd4ql3cct.onion")
        XCTAssertFalse(site.allowed)
        await asyncTearDown()
    }
    
    func testNextSiteToProcess() async {
        await asyncSetup()
        var site = Site(url: "http://darkeyejce5fone2srstf3j26u6jbjpctkwejiis6qsrqxbpa4k4hlad.onion/darkeye")
        try? await database.setValue(site, forKey: "site-darkeyejce5fone2srstf3j26u6jbjpctkwejiis6qsrqxbpa4k4hlad")
        site = Site(url: "http://haneinhodfxcjcnsm6efuyzdffcrejd7jmstte7hwdvhf67x6okyb2ad.onion")
        try? await database.setValue(site, forKey: "site-haneinhodfxcjcnsm6efuyzdffcrejd7jmstte7hwdvhf67x6okyb2ad")
        let nextSite = await Site.nextSiteToProcess()
        XCTAssertEqual(nextSite?.url, "http://haneinhodfxcjcnsm6efuyzdffcrejd7jmstte7hwdvhf67x6okyb2ad.onion")
        await asyncTearDown()
    }
    
    func testSave() async {
        await asyncSetup()
        var site = Site(url: "http://hanein2.onion")
        await site.save()
        site = Site(url: "http://hanein1.onion")
        await site.save()
        let firstKey = await Site.firstKey()
        XCTAssertEqual(firstKey, "site-hanein1")
        XCTAssertEqual(site.url, "http://hanein1.onion")
        await asyncTearDown()
    }
    
    func crawlNext() async {
        await asyncSetup()
        await Site.crawlNext()
        if let _: Site = await database.value(forKey: Site.prefix + "duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad") {
        } else {
            XCTFail()
        }
        await asyncTearDown()
    }
}
