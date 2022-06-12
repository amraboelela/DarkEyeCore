import XCTest
@testable import DarkEyeCore

final class WordTests: XCTestCase {
    var mainPageHtml = ""
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testWordsFromText() {
        var words = Word.words(fromText: " Hey a of in the \n man   ")
        XCTAssertEqual(words.count, 6)
        XCTAssertEqual(words[0], "hey")
        XCTAssertEqual(words[1], "a")
        XCTAssertEqual(words[2], "of")
        XCTAssertEqual(words[3], "in")
        XCTAssertEqual(words[4], "the")
        XCTAssertEqual(words[5], "man")
        
        var link = Link(url: "http://hanein1.onion")
        link.load()
        words = Word.words(fromText: link.text)
        XCTAssertEqual(words.count, 4856)
        print("testWordsFromText words: \(words)")
    }
    
}
