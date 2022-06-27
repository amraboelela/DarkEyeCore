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
    
    func testText() {
        var link = Link(url: crawler.mainUrl)
        link.html = "<head><title>Dark Eye<title></head>"
        var text = link.text
        XCTAssertEqual(text, "Dark Eye")
        link.html = """
            <html><head><title>Dark Eye<title></head>
            <body><ul><li>
            <input type='image' name='input1' value='string1value' class='abc' /></li>
            <li><input type='image' name='input2' value='string2value' class='def' /></li></ul>
            <span class='spantext'><b>Hello World 1</b></span>
            <span class='spantext'><b>Hello World 2</b></span>
            <a href='example.com'>example(English)</a>
            <a href='example.co.jp'>example(JP)</a>
            </body>
        """
        text = link.text
        XCTAssertEqual(text, "Dark Eye Hello World 1 Hello World 2 example(English) example(JP)")
        link.load()
        text = link.text
        print("text.count: \(text.count)")
        XCTAssertTrue(text.count > 27000)
    }
    
    func testUrls() {
        var link = Link(url: crawler.mainUrl)
        link.html = "<head><title>Dark Eye<title></head>"
        var urls = link.urls
        XCTAssertEqual(urls.count, 0)
        link.html = """
            <html><head><title>Dark Eye<title></head>
            <body><ul><li>
            <input type='image' name='input1' value='string1value' class='abc' /></li>
            <li><input type='image' name='input2' value='string2value' class='def' /></li></ul>
            <span class='spantext'><b>Hello World 1</b></span>
            <span class='spantext'><b>Hello World 2</b></span>
            <a href='http://example.onion/'>example(English)</a>
            <a href='http://example.co.onion'>example(JP)</a>
            <a href='/mashy/ya/3am/'>example(JP)</a>
            </body>
        """
        urls = link.urls
        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(urls[0], "http://example.onion")
        XCTAssertEqual(urls[1], "http://example.co.onion")
        XCTAssertEqual(urls[2], "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/mashy/ya/3am")
        
        link.load()
        urls = link.urls
        print("urls.count: \(urls.count)")
        XCTAssertTrue(urls.count > 200)
        XCTAssertEqual(urls[0], "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion")
        let wikiUrls = urls.filter { $0.range(of: "/wiki")?.lowerBound == $0.startIndex }
        XCTAssertEqual(wikiUrls.count, 0)
        let dotOrgUrls = urls.filter { $0.range(of: ".org") != nil }
        XCTAssertEqual(dotOrgUrls.count, 0)
        let dotComUrls = urls.filter { $0.range(of: ".com") != nil }
        XCTAssertEqual(dotComUrls.count, 0)
        let xmppUrls = urls.filter { $0.range(of: "xmpp") != nil }
        XCTAssertEqual(xmppUrls.count, 0)
        let ircUrls = urls.filter { $0.range(of: "irc") != nil }
        XCTAssertEqual(ircUrls.count, 0)
        let notOnionUrls = urls.filter { $0.range(of: ".onion") == nil }
        XCTAssertEqual(notOnionUrls.count, 0)
        let notHttpUrls = urls.filter { $0.range(of: "http") == nil }
        XCTAssertEqual(notHttpUrls.count, 0)
    }
    
    func testCachedFile() {
        var link = Link(url: crawler.mainUrl)
        link.save()
        let cachedFile = link.cachedFile()
        XCTAssertNotNil(cachedFile)
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
        var link = Link(url: crawler.mainUrl)
        link.load()
        XCTAssertNotNil(link.html)
    }
    
    func testProcessLink() {
        let url = "http://library123.onion"
        var link = Link(url: url, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, html: "<html><body><p>I went to college to go to the library</p></body></html>")
        XCTAssertEqual(link.lastProcessTime, 0)
        crawler.canRun = true
        Link.process(link: link)
        let processedExpectation = expectation(description: "link processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if let dbLink: Link = database[Link.prefix + url] {
                XCTAssertNotEqual(dbLink.lastProcessTime, 0)
            } else {
                XCTFail()
            }
            if let word: Word = database[Word.prefix + "library"] {
                XCTAssertTrue(word.links[0].text.lowercased().contains("library"))
                XCTAssertEqual(word.links[0].url, url)
                processedExpectation.fulfill()
            } else {
                XCTFail()
            }
            if let _: Word = database[Word.prefix + "body"] {
                XCTFail()
            }
            if let _: Word = database[Word.prefix + "html"] {
                XCTFail()
            }
        }
        link = Link(url: crawler.mainUrl)
        Link.process(link: link)
        let link2ProcessedExpectation = expectation(description: "link2 processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if let word: Word = database[Word.prefix + "bitcoin"] {
                XCTAssertTrue(word.links[0].text.lowercased().contains("bitcoin"))
            } else {
                XCTFail()
            }
            if let word: Word = database[Word.prefix + "the"] {
                XCTAssertTrue(word.links[0].text.lowercased().contains("the"))
            } else {
                XCTFail()
            }
            if let word: Word = database[Word.prefix + "hidden"] {
                XCTAssertTrue(word.links[0].text.lowercased().contains("hidden"))
                link2ProcessedExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testProcessBlockedLink() {
        let url = "http://library123.onion"
        let link = Link(url: url, hash: "", lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, numberOfReports: 0, blocked: true, html: "<html><body><p>I went to college to go to the library</p></body></html>")
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
    
    func testSaveChildren() {
        var link = Link(url: crawler.mainUrl, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, html: "<html><body><p>I went to college to go to the library</p></body></html>")
        XCTAssertEqual(link.lastProcessTime, 0)
        crawler.canRun = true
        link.saveChildren()
        var success = Word.index(link: link)
        XCTAssertTrue(success)
        if let word: Word = database[Word.prefix + "library"] {
            XCTAssertTrue(word.links[0].text.lowercased().contains("library"))
            XCTAssertEqual(word.links[0].url, crawler.mainUrl)
        } else {
            XCTFail()
        }
        if let _: Word = database[Word.prefix + "body"] {
            XCTFail()
        }
        if let _: Word = database[Word.prefix + "html"] {
            XCTFail()
        }
        link = Link(url: crawler.mainUrl)
        link.saveChildren()
        success = Word.index(link: link)
        XCTAssertTrue(success)
        if let word: Word = database[Word.prefix + "bitcoin"] {
            XCTAssertTrue(word.links[0].text.lowercased().contains("bitcoin"))
        } else {
            XCTFail()
        }
        if let word: Word = database[Word.prefix + "the"] {
            XCTAssertTrue(word.links[0].text.lowercased().contains("the"))
        } else {
            XCTFail()
        }
        if let word: Word = database[Word.prefix + "hidden"] {
            XCTAssertTrue(word.links[0].text.lowercased().contains("hidden"))
        } else {
            XCTFail()
        }
    }
    
    func testCrawl() {
        var link = Link(url: crawler.mainUrl)
        link.crawl()
        if let _: Link = database[Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion"] {
        } else {
            XCTFail()
        }
    }
    
    func testUrlFromKey() {
        let url = Link.url(fromKey: "link-http://hanein1.onion")
        XCTAssertEqual(url, "http://hanein1.onion")
    }
}
