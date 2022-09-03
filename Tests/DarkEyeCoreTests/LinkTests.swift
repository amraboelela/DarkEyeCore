import XCTest
@testable import DarkEyeCore

final class LinkTests: TestsBase {
    
    override func asyncSetup() async {
        await super.asyncSetup()
    }
    
    override func asyncTearDown() async {
        await super.asyncTearDown()
    }
    
    func testFirstKey() async {
        await asyncSetup()
        try? await database.setValue(
            Link(url: "http://hanein1.onion"),
            forKey: "link-http://hanein1.onion"
        )
        try? await database.setValue(
            Link(url: "http://hanein2.onion"),
            forKey: "link-http://hanein2.onion"
        )
        try? await database.setValue(
            Link(url: "http://hanein3.onion"),
            forKey: "link-http://hanein3.onion"
        )
        let firstKey = await Link.firstKey()
        XCTAssertEqual(firstKey, "link-http://hanein1.onion")
        await asyncTearDown()
    }
    
    func testKey() async {
        await asyncSetup()
        let link = Link(url: "http://hanein1.onion")
        XCTAssertEqual(link.key, "link-http://hanein1.onion")
        await asyncTearDown()
    }
    
    func testBase() async {
        await asyncSetup()
        let link = Link(url: "http://hanein1.onion/main")
        XCTAssertEqual(link.base, "http://hanein1.onion")
        await asyncTearDown()
    }
    
    func testNextLinkToProcess() async {
        await asyncSetup()
        let url = "http://hanein1.onion"
        let link = Link(url: url)
        try? await database.setValue(link, forKey: "link-" + url)
        let nextLink = await Link.nextLinkToProcess()
        XCTAssertNotNil(nextLink)
        await asyncTearDown()
    }
    
    func testText() async {
        await asyncSetup()
        let link = Link(url: Link.mainUrl)
        let text = link.text
        XCTAssertTrue(text.contains("Verifying PGP signatures - A short and simple how-to guide. In Praise Of Hawala - Anonymous"))
        print("text.count: \(text.count)")
        XCTAssertTrue(text.count > 27000)
        await asyncTearDown()
    }
    
    func testRawUrls() async {
        await asyncSetup()
        let link = Link(url: Link.mainUrl)
        var urls = link.urls
        XCTAssertEqual(urls.count, 257)
        urls = link.urls
        XCTAssertEqual(urls.count, 257)
        XCTAssertEqual(urls[0].0, "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion")
        XCTAssertEqual(urls[1].0, "/wiki/Contest2022")
        XCTAssertEqual(urls[2].0, "/wiki/The_Matrix")
    
        urls = link.urls
        print("urls.count: \(urls.count)")
        XCTAssertTrue(urls.count > 200)
        XCTAssertEqual(urls[0].0, "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion")
        let wikiUrls = urls.filter { rawURL, refinedURL in
            rawURL.range(of: "/wiki")?.lowerBound == rawURL.startIndex
        }
        XCTAssertEqual(wikiUrls.count, 32)
        let dotOrgUrls = urls.filter { rawURL, refinedURL in
            rawURL.range(of: ".org") != nil
        }
        XCTAssertEqual(dotOrgUrls.count, 0)
        let dotComUrls = urls.filter { rawURL, refinedURL in
            rawURL.range(of: ".com") != nil
        }
        XCTAssertEqual(dotComUrls.count, 0)
        let xmppUrls = urls.filter { rawURL, refinedURL in
            rawURL.range(of: "xmpp") != nil
        }
        XCTAssertEqual(xmppUrls.count, 0)
        let ircUrls = urls.filter { rawURL, refinedURL in
            rawURL.range(of: "irc") != nil
        }
        XCTAssertEqual(ircUrls.count, 0)
        let notOnionUrls = urls.filter { rawURL, refinedURL in
            rawURL.range(of: ".onion") == nil
        }
        XCTAssertEqual(notOnionUrls.count, 32)
        let notHttpUrls = urls.filter { rawURL, refinedURL in
            rawURL.range(of: "http") == nil
        }
        XCTAssertEqual(notHttpUrls.count, 32)
        await asyncTearDown()
    }
    
    func testRefindedUrls() async {
        await asyncSetup()
        let link = Link(url: Link.mainUrl)
        var urls = link.urls
        XCTAssertEqual(urls.count, 257)
        urls = link.urls
        XCTAssertEqual(urls.count, 257)
        XCTAssertEqual(urls[0].1, "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion")
        XCTAssertEqual(urls[1].1, "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Contest2022")
        XCTAssertEqual(urls[2].1, "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/The_Matrix")
        urls = link.urls
        print("urls.count: \(urls.count)")
        XCTAssertTrue(urls.count > 200)
        XCTAssertEqual(urls[0].1, "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion")
        let wikiUrls = urls.filter { rawURL, refinedURL in
            refinedURL.range(of: "/wiki")?.lowerBound == refinedURL.startIndex
        }
        XCTAssertEqual(wikiUrls.count, 0)
        let dotOrgUrls = urls.filter { rawURL, refinedURL in
            refinedURL.range(of: ".org") != nil
        }
        XCTAssertEqual(dotOrgUrls.count, 0)
        let dotComUrls = urls.filter { rawURL, refinedURL in
            refinedURL.range(of: ".com") != nil
        }
        XCTAssertEqual(dotComUrls.count, 0)
        let xmppUrls = urls.filter { rawURL, refinedURL in
            refinedURL.range(of: "xmpp") != nil
        }
        XCTAssertEqual(xmppUrls.count, 0)
        let ircUrls = urls.filter { rawURL, refinedURL in
            refinedURL.range(of: "irc") != nil
        }
        XCTAssertEqual(ircUrls.count, 0)
        let notOnionUrls = urls.filter { rawURL, refinedURL in
            refinedURL.range(of: ".onion") == nil
        }
        XCTAssertEqual(notOnionUrls.count, 0)
        let notHttpUrls = urls.filter { rawURL, refinedURL in
            refinedURL.range(of: "http") == nil
        }
        XCTAssertEqual(notHttpUrls.count, 0)
        await asyncTearDown()
    }
    
    func testHtml() async {
        await asyncSetup()
        var link = Link(url: Link.mainUrl)
        try? await link.save()
        let html = link.html
        XCTAssertNotNil(html)
        await asyncTearDown()
    }
    
    func testWithUrl() async {
        await asyncSetup()
        let link = Link.with(url: "http://hanein1.onion")
        XCTAssertEqual(link.url, "http://hanein1.onion")
        await asyncTearDown()
    }
    
    func testFromKey() async {
        await asyncSetup()
        let link = Link.from(key: "link-http://hanein1.onion")
        XCTAssertEqual(link.url, "http://hanein1.onion")
        await asyncTearDown()
    }
    
    func testSave() async {
        await asyncSetup()
        var link = Link(url: "http://hanein1.onion")
        try? await link.save()
        let firstKey = await Link.firstKey()
        XCTAssertEqual(firstKey, "link-http://hanein1.onion")
        XCTAssertEqual(link.hash, "http://hanein1.onion".hashBase32(numberOfDigits: 12))
        if let hashLink: HashLink = await database.valueForKey(HashLink.prefix + "http://hanein1.onion".hashBase32(numberOfDigits: 12)) {
            XCTAssertEqual(hashLink.url, "http://hanein1.onion")
        } else {
            XCTFail()
        }
        link = Link(url: "http://hanein2.onion")
        try? await link.save()
        link = Link(url: "http://hanein1.onion")
        try? await link.save()
        await asyncTearDown()
    }
    
    func testLoad() async {
        await asyncSetup()
        let link = Link(url: Link.mainUrl)
        XCTAssertNotNil(link.html)
        await asyncTearDown()
    }
    
    func testProcessLink() async {
        await asyncSetup()
        let timeDelay = 5.0
        let link1 = Link(url: Link.mainUrl)
        try? await Link.process(link: link1)
        let link1ProcessedExpectation = expectation(description: "link1 processed")
        try? await Task.sleep(seconds: timeDelay)
        if let word: Word = await database.valueForKey(Word.prefix + "jump") {
            XCTAssertTrue(word.links[0].text.lowercased().contains("jump"))
            link1ProcessedExpectation.fulfill()
        } else {
            XCTFail()
        }
        await waitForExpectations(timeout: timeDelay * 2, handler: nil)
        await asyncTearDown()
    }
    
    func testProcessBlockedLink() async {
        await asyncSetup()
        let url = "http://library123.onion"
        let link = Link(url: url, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, numberOfReports: 0, blocked: true)
        XCTAssertEqual(link.lastProcessTime, 0)
        let crawler = try! await Crawler.shared()
        crawler.canRun = true
        try? await Link.process(link: link)
        let blockedExpectation = expectation(description: "link is blocked")
        try? await Task.sleep(seconds: 5)
        if let dbLink: Link = await database.valueForKey(Link.prefix + url) {
            XCTAssertNotEqual(dbLink.lastProcessTime, 0)
        } else {
            XCTFail()
        }
        if let _: Word = await database.valueForKey(Word.prefix + "library") {
            XCTFail()
        } else {
            blockedExpectation.fulfill()
        }
        await waitForExpectations(timeout: 10.0, handler: nil)
        await asyncTearDown()
    }
    
    func testSaveChildrenIfNeeded() async {
        await asyncSetup()
        var link = Link(url: Link.mainUrl, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0)
        link.lastProcessTime = Date.secondsSinceReferenceDate
        try? await link.saveChildrenIfNeeded()
        if let _: Link = await database.valueForKey(Link.prefix + "exampleenglish.onion") {
            XCTFail()
        }
        if let _: Link = await database.valueForKey(Link.prefix + "examplejapan.onion") {
            XCTFail()
        }
        await asyncTearDown()
    }
    
    func testSaveChildren() async {
        await asyncSetup()
        var link = Link(url: Link.mainUrl, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0)
        XCTAssertEqual(link.lastProcessTime, 0)
        try? await link.saveChildren()
        if let _: Link = await database.valueForKey(Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion") {
        } else {
            XCTFail()
        }
        await asyncTearDown()
    }
    
    func crawlNext() async {
        await asyncSetup()
        try? await Link.crawlNext()
        if let _: Link = await database.valueForKey(Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion") {
        } else {
            XCTFail()
        }
        await asyncTearDown()
    }
    
    func testUrlFromKey() async {
        await asyncSetup()
        let url = Link.url(fromKey: "link-http://hanein1.onion")
        XCTAssertEqual(url, "http://hanein1.onion")
        await asyncTearDown()
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
    
    func testRemoveURL() async {
        await asyncSetup()
        let url = "http://2a2a2abbjsjcjwfuozip6idfxsxyowoi3ajqyehqzfqyxezhacur7oyd.onion"
        let hash = url.hashBase32(numberOfDigits: 12)
        Link.remove(url: url)
        let filePath = Link.cacheURL.appendingPathComponent(hash + ".html").path
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath))
        await asyncTearDown()
    }
}
