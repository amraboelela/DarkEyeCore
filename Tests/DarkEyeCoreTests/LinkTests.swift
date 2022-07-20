import XCTest
@testable import DarkEyeCore

final class LinkTests: TestsBase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFirstKey() {
        database["link-http://hanein1.onion"] = Link(url: "http://hanein1.onion")
        database["link-http://hanein2.onion"] = Link(url: "http://hanein2.onion")
        database["link-http://hanein3.onion"] = Link(url: "http://hanein3.onion")
        XCTAssertEqual(Link.firstKey, "link-http://hanein1.onion")
    }
    
    func testKey() {
        let link = Link(url: "http://hanein1.onion")
        XCTAssertEqual(link.key, "link-http://hanein1.onion")
    }
    
    func testBase() {
        let link = Link(url: "http://hanein1.onion/main")
        XCTAssertEqual(link.base, "http://hanein1.onion")
    }
    
    func testNextLinkToProcess() {
        let url = "http://hanein1.onion"
        let link = Link(url: url)
        database["link-" + url] = link
        let nextLink = Link.nextLinkToProcess()
        XCTAssertNotNil(nextLink)
    }
    
    func testText() {
        let link = Link(url: Link.mainUrl)
        let text = link.text
        XCTAssertTrue(text.contains("Verifying PGP signatures - A short and simple how-to guide. In Praise Of Hawala - Anonymous"))
        print("text.count: \(text.count)")
        XCTAssertTrue(text.count > 27000)
    }
    
    func testRawUrls() {
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
    }
    
    func testRefindedUrls() {
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
    }
    
    func testHtml() {
        var link = Link(url: Link.mainUrl)
        link.save()
        let html = link.html
        XCTAssertNotNil(html)
    }
    
    func testWithUrl() {
        let link = Link.with(url: "http://hanein1.onion")
        XCTAssertEqual(link.url, "http://hanein1.onion")
    }
    
    func testFromKey() {
        let link = Link.from(key: "link-http://hanein1.onion")
        XCTAssertEqual(link.url, "http://hanein1.onion")
    }
    
    func testSave() {
        var link = Link(url: "http://hanein1.onion")
        link.save()
        XCTAssertEqual(Link.firstKey, "link-http://hanein1.onion")
        XCTAssertEqual(link.hash, "http://hanein1.onion".hashBase32(numberOfDigits: 12))
        if let hashLink: HashLink = database[HashLink.prefix + "http://hanein1.onion".hashBase32(numberOfDigits: 12)] {
            XCTAssertEqual(hashLink.url, "http://hanein1.onion")
        } else {
            XCTFail()
        }
        link = Link(url: "http://hanein2.onion")
        link.save()
        link = Link(url: "http://hanein1.onion")
        link.save()
    }
    
    func testLoad() {
        let link = Link(url: Link.mainUrl)
        XCTAssertNotNil(link.html)
    }
    
    func testProcessLink() {
        let timeDelay = 5.0
        let link2 = Link(url: Link.mainUrl)
        Link.process(link: link2)
        let link2ProcessedExpectation = expectation(description: "link2 processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeDelay * 2) {
            if let word: Word = database[Word.prefix + "accepted"] {
                XCTAssertTrue(word.links[0].text.lowercased().contains("accepted"))
                link2ProcessedExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: timeDelay * 3, handler: nil)
    }
    
    func testProcessBlockedLink() {
        let url = "http://library123.onion"
        let link = Link(url: url, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, numberOfReports: 0, blocked: true)
        XCTAssertEqual(link.lastProcessTime, 0)
        crawler.canRun = true
        Link.process(link: link)
        let blockedExpectation = expectation(description: "link is blocked")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if let dbLink: Link = database[Link.prefix + url] {
                XCTAssertNotEqual(dbLink.lastProcessTime, 0)
            } else {
                XCTFail()
            }
            if let _: Word = database[Word.prefix + "library"] {
                XCTFail()
            } else {
                blockedExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testSaveChildrenIfNeeded() {
        var link = Link(url: Link.mainUrl, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0)
        link.lastProcessTime = Date.secondsSinceReferenceDate
        link.saveChildrenIfNeeded()
        if let _: Link = database[Link.prefix + "exampleenglish.onion"] {
            XCTFail()
        }
        if let _: Link = database[Link.prefix + "examplejapan.onion"] {
            XCTFail()
        }
    }
    
    func testSaveChildren() {
        var link = Link(url: Link.mainUrl, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0)
        XCTAssertEqual(link.lastProcessTime, 0)
        link.saveChildren()
        if let _: Link = database[Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion"] {
        } else {
            XCTFail()
        }
    }
    
    func crawlNext() {
        Link.crawlNext()
        if let _: Link = database[Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion"] {
        } else {
            XCTFail()
        }
    }
    
    func testUrlFromKey() {
        let url = Link.url(fromKey: "link-http://hanein1.onion")
        XCTAssertEqual(url, "http://hanein1.onion")
    }
    
    func testAllowedUrl() {
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
    }
    
    func testRemoveURL() {
        let url = "http://2a2a2abbjsjcjwfuozip6idfxsxyowoi3ajqyehqzfqyxezhacur7oyd.onion"
        let hash = url.hashBase32(numberOfDigits: 12)
        Link.remove(url: url)
        let filePath = Link.cacheURL.appendingPathComponent(hash + ".html").path
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath))
    }
}
