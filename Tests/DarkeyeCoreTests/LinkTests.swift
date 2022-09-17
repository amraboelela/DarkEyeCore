import XCTest
@testable import DarkeyeCore

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
        let link = Link(url: Global.mainUrls.first!)
        let text = await link.text()
        XCTAssertTrue(text.contains("The Hidden Wiki"))
        print("text.count: \(text.count)")
        XCTAssertTrue(text.count > 27000)
        await asyncTearDown()
    }
    
    func testRawUrls() async {
        await asyncSetup()
        let link = Link(url: Global.mainUrls.first!)
        var urls = await link.urls()
        XCTAssertTrue(urls.count > 100)
        XCTAssertEqual(urls[0].0, "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion")
        XCTAssertEqual(urls[1].0, "/wiki/Contest2022")
        XCTAssertEqual(urls[2].0, "/wiki/The_Matrix")
    
        urls = await link.urls()
        print("urls.count: \(urls.count)")
        let wikiUrls = urls.filter { rawURL, refinedURL in
            rawURL.range(of: "/wiki")?.lowerBound == rawURL.startIndex
        }
        XCTAssertTrue(wikiUrls.count > 30)
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
        await asyncTearDown()
    }
    
    func testRefindedUrls() async {
        await asyncSetup()
        let link = Link(url: Global.mainUrls.first!)
        let urls = await link.urls()
        XCTAssertTrue(urls.count > 200)
        XCTAssertEqual(urls[0].1, "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion")
        XCTAssertEqual(urls[1].1, "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Contest2022")
        XCTAssertEqual(urls[2].1, "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/The_Matrix")
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
        var link = Link(url: Global.mainUrls.first!)
        await link.save()
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
        var link = Link(url: "http://hanein2.onion")
        await link.save()
        link = Link(url: "http://hanein1.onion")
        await link.save()
        let firstKey = await Link.firstKey()
        XCTAssertEqual(firstKey, "link-http://hanein1.onion")
        XCTAssertEqual(link.hash, "http://hanein1.onion".hashBase32(numberOfDigits: 12))
        if let hashLink: HashLink = await database.value(forKey: HashLink.prefix + "http://hanein1.onion".hashBase32(numberOfDigits: 12)) {
            XCTAssertEqual(hashLink.url, "http://hanein1.onion")
        } else {
            XCTFail()
        }
        await asyncTearDown()
    }
    
    func testLoad() async {
        await asyncSetup()
        let link = Link(url: Global.mainUrls.first!)
        XCTAssertNotNil(link.html)
        await asyncTearDown()
    }
    
    func testProcessLink() async {
        await asyncSetup()
        let link1 = Link(url: Global.mainUrls.first!)
        try? await Link.process(link: link1)
        try? await Task.sleep(seconds: 5)
        if let word: WordLink = await database.value(forKey: WordLink.prefix + "wiki-" + Global.mainUrls.first!) {
            XCTAssertTrue(word.text.lowercased().contains("wiki"))
        } else {
            XCTFail()
        }
        await asyncTearDown()
    }
    
    func testProcessBlockedLink() async {
        await asyncSetup()
        let url = "http://library123.onion"
        let link = Link(url: url, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0)
        XCTAssertEqual(link.lastProcessTime, 0)
        let crawler = await Crawler.shared()
        crawler.canRun = true
        try? await Link.process(link: link)
        try? await Task.sleep(seconds: 5)
        if let dbLink: Link = await database.value(forKey: Link.prefix + url) {
            XCTAssertNotEqual(dbLink.lastProcessTime, 0)
        } else {
            XCTFail()
        }
        //print("testProcessBlockedLink after if let dbLink: Link ")
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "library") {
            XCTFail()
        }
        await asyncTearDown()
    }
    
    func testSaveChildrenIfNeeded() async {
        await asyncSetup()
        var link = Link(url: Global.mainUrls.first!, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0)
        link.lastProcessTime = Date.secondsSinceReferenceDate
        await link.saveChildrenIfNeeded()
        if let _: Link = await database.value(forKey: Link.prefix + "exampleenglish.onion") {
            XCTFail()
        }
        if let _: Link = await database.value(forKey: Link.prefix + "examplejapan.onion") {
            XCTFail()
        }
        await asyncTearDown()
    }
    
    func testSaveChildren() async {
        await asyncSetup()
        var link = Link(url: Global.mainUrls.first!, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0)
        XCTAssertEqual(link.lastProcessTime, 0)
        await link.saveChildren()
        if let _: Site = await database.value(forKey: Site.prefix + "zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad") {
        } else {
            XCTFail()
        }
        await asyncTearDown()
    }
    
    func crawlNext() async {
        await asyncSetup()
        try? await Link.crawlNext()
        if let _: Link = await database.value(forKey: Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion") {
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
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/beverages/vodka")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/beverages/whiskey")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/file.zip")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/file.jpg")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/file.png")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/file.mp4")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/file.epub")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/@file")
        XCTAssertFalse(allowed)
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/file.html")
        XCTAssertTrue(allowed)
        allowed = Link.allowed(url: "http://27m3p2uv7igmj6kvd4ql3cct5h3sdwrsajovkkndeufumzyfhlfev4qd.onion/2022/02/17/richard-ciano-donation-freedom-convoy-canada-givesendgo/?menu=1")
        XCTAssertFalse(allowed)
        
        allowed = Link.allowed(url: "/search/search/redirect?search_term=war on ukrain&redirect_url=http://bafkad5xfa6zbzhyvczf24j4ppbc4ylcavgwnmkppccikejzbdxzxlad.onion/node/205669")
        XCTAssertFalse(allowed)
        
        await asyncTearDown()
    }
}
