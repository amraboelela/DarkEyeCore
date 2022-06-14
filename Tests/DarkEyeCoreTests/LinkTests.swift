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
        //print("main_page.html text: \(text)")
        XCTAssertTrue(text.count > 28150)
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
        XCTAssertTrue(urls.count >= 230)
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
    
    func testWithUrl() {
        let link = Link.with(url: "http://hanein1.onion")
        XCTAssertEqual(link.url, "http://hanein1.onion")
    }
    
    func testFromKey() {
        let link = Link.from(key: "link-http://hanein1.onion")
        XCTAssertEqual(link.url, "http://hanein1.onion")
    }
    
    func testLinks() {
        let links = Link.links(withSearchText: "wiki", count: 20)
        XCTAssertEqual(links.count, 0)
    }
    
    func testSave() {
        var link = Link(url: "http://hanein1.onion")
        var saved = link.save()
        XCTAssertTrue(saved)
        XCTAssertEqual(Link.firstKey, "link-http://hanein1.onion")
        link = Link(url: "http://hanein2.onion")
        saved = link.save()
        XCTAssertTrue(saved)
        link = Link(url: "http://hanein1.onion")
        saved = link.save()
        XCTAssertFalse(saved)
    }
    
    func testLoad() {
        var link = Link(url: crawler.mainUrl)
        link.load()
        XCTAssertNotNil(link.html)
    }
    
    func testProcess() {
        var link = Link(url: crawler.mainUrl, lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, html: "<html><body><p>I went to college to go to the library</p></body></html>")
        XCTAssertEqual(link.lastProcessTime, 0)
        link.process()
        XCTAssertNotEqual(link.lastProcessTime, 0)
        if let word: Word = database[Word.prefix + "library"] {
            XCTAssertTrue(word.links[0].text.lowercased().contains("library"))
            XCTAssertEqual(word.links[0].url, crawler.mainUrl)
        } else {
            XCTFail()
        }
        if let _: Word = database[Word.prefix + "body"] {
            XCTFail()
        }
        if let _: Word = database[Word.prefix + "college"] {
            XCTFail()
        }
        link = Link(url: crawler.mainUrl)
        link.process()
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
