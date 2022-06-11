import XCTest
@testable import DarkEyeCore

final class WordTests: XCTestCase {
    var mainPageHtml = ""
    
    override func setUp() {
        super.setUp()
        let testRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "DarkEyeCoreTests/WordTests.swift", with: "/")).path
        let fileURL = URL(fileURLWithPath: testRoot + "Resources").appendingPathComponent("main_page.html")
        do {
            mainPageHtml = try String(contentsOf: fileURL, encoding: .utf8)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTextFromHtml() {
        var html = "<head><title>Dark Eye<title></head>"
        var text = Word.text(fromHtml: html)
        XCTAssertEqual(text, "Dark Eye")
        html = """
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
        text = Word.text(fromHtml: html)
        XCTAssertEqual(text, "Dark Eye Hello World 1 Hello World 2 example(English) example(JP)")
        
        text = Word.text(fromHtml: mainPageHtml)
        print("main_page.html text: \(text)")
        XCTAssertEqual(text.count, 28390)
    }
    
    func testUrlsFromHtml() {
        var html = "<head><title>Dark Eye<title></head>"
        var urls = Word.urls(fromHtml: html)
        XCTAssertEqual(urls.count, 0)
        html = """
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
        urls = Word.urls(fromHtml: html)
        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0], "example.com")
        XCTAssertEqual(urls[1], "example.co.jp")
        
        urls = Word.urls(fromHtml: mainPageHtml)
        XCTAssertEqual(urls.count, 361)
        XCTAssertEqual(urls[0], "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion")
        XCTAssertEqual(urls[1], "/wiki/Contest2022")
    }
    
    func testWordsFromText() {
        let words = Word.words(fromText: " Hey a of in the \n man   ")
        XCTAssertEqual(words.count, 6)
        XCTAssertEqual(words[0], "hey")
        XCTAssertEqual(words[1], "a")
        XCTAssertEqual(words[2], "of")
        XCTAssertEqual(words[3], "in")
        XCTAssertEqual(words[4], "the")
        XCTAssertEqual(words[5], "man")
    }
    
}
