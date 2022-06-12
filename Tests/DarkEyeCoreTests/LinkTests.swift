import XCTest
@testable import DarkEyeCore

final class LinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let testRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "DarkEyeCoreTests/LinkTests.swift", with: "/")).path
        database = Database(parentPath: testRoot + "Library", name: "Database")
    }
    
    override func tearDown() {
        super.tearDown()
        database.deleteDatabaseFromDisk()
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
        var link = Link(url: "http://hanein1.onion")
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
        print("main_page.html text: \(text)")
        XCTAssertEqual(text.count, 28390)
    }
    
    func testUrls() {
        var link = Link(url: "http://hanein1.onion")
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
            <a href='example.onion'>example(English)</a>
            <a href='example.co.onion'>example(JP)</a>
            </body>
        """
        urls = link.urls
        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0], "example.onion")
        XCTAssertEqual(urls[1], "example.co.onion")
        
        link.load()
        urls = link.urls
        XCTAssertEqual(urls.count, 287)
        XCTAssertEqual(urls[0], "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion")
        let wikiUrls = urls.filter { $0.range(of: "/wiki")?.lowerBound == $0.startIndex }
        XCTAssertEqual(wikiUrls.count, 0)
        let dotOrgUrls = urls.filter { $0.range(of: ".org") != nil }
        XCTAssertEqual(dotOrgUrls.count, 0)
        let dotComUrls = urls.filter { $0.range(of: ".com") != nil }
        XCTAssertEqual(dotComUrls.count, 0)
        let notOnionUrls = urls.filter { $0.range(of: ".onion") == nil }
        XCTAssertEqual(notOnionUrls.count, 0)
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
        var link = Link(url: "http://hanein1.onion")
        link.load()
        XCTAssertNotNil(link.html)
    }
    
    func testProcess() {
        var link = Link(url: "http://hanein1.onion")
        XCTAssertEqual(link.lastProcessTime, 0)
        link.process()
        XCTAssertNotEqual(link.lastProcessTime, 0)
    }
    
    func testUrlFromKey() {
        let url = Link.url(fromKey: "link-http://hanein1.onion")
        XCTAssertEqual(url, "http://hanein1.onion")
    }
    
}
