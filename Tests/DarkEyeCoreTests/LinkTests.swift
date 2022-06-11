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
        database["link-http://hanein1.news"] = Link(url: "http://hanein1.news")
        database["link-http://hanein2.news"] = Link(url: "http://hanein2.news")
        database["link-http://hanein3.news"] = Link(url: "http://hanein3.news")
        XCTAssertEqual(Link.firstKey, "link-http://hanein1.news")
    }
    
    func testKey() {
        let link = Link(url: "http://hanein1.news")
        XCTAssertEqual(link.key, "link-http://hanein1.news")
    }
    
    func testWithUrl() {
        let link = Link.with(url: "http://hanein1.news")
        XCTAssertEqual(link.url, "http://hanein1.news")
    }
    
    func testFromKey() {
        let link = Link.from(key: "link-http://hanein1.news")
        XCTAssertEqual(link.url, "http://hanein1.news")
    }
    
    func testLinks() {
        let links = Link.links(withSearchText: "wiki", count: 20)
        XCTAssertEqual(links.count, 0)
    }
    
    func testSave() {
        var link = Link(url: "http://hanein1.news")
        var saved = link.save()
        XCTAssertTrue(saved)
        XCTAssertEqual(Link.firstKey, "link-http://hanein1.news")
        link = Link(url: "http://hanein2.news")
        saved = link.save()
        XCTAssertTrue(saved)
        link = Link(url: "http://hanein1.news")
        saved = link.save()
        XCTAssertFalse(saved)
    }
    
    func testLoad() {
        var link = Link(url: "http://hanein1.news")
        link.load()
        XCTAssertNotNil(link.html)
    }
    
    func testProcess() {
        var link = Link(url: "http://hanein1.news")
        XCTAssertEqual(link.lastProcessTime, 0)
        link.process()
        XCTAssertNotEqual(link.lastProcessTime, 0)
    }
    
    func testUrlFromKey() {
        let url = Link.url(fromKey: "link-http://hanein1.news")
        XCTAssertEqual(url, "http://hanein1.news")
    }
    
    func testText() {
        var link = Link(url: "http://hanein1.news")
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
        var link = Link(url: "http://hanein1.news")
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
            <a href='example.com'>example(English)</a>
            <a href='example.co.jp'>example(JP)</a>
            </body>
        """
        urls = link.urls
        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0], "example.com")
        XCTAssertEqual(urls[1], "example.co.jp")
        
        link.load()
        urls = link.urls
        XCTAssertEqual(urls.count, 361)
        XCTAssertEqual(urls[0], "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion")
        XCTAssertEqual(urls[1], "/wiki/Contest2022")
    }
    
}
