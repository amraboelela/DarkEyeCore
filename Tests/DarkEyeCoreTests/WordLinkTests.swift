import XCTest
@testable import DarkEyeCore

final class WordLinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testScore() {
        var wordLink = WordLink(url: "http://hanein123.onion", text: "I am good thank you", wordCount: 1, numberOfVisits: 1, lastVisitTime: 10)
        XCTAssertEqual(wordLink.score, 1011)
        wordLink = WordLink(url: "http://hanein123.onion", text: "I am good thank you", wordCount: 1, numberOfVisits: 2, lastVisitTime: 10)
        XCTAssertEqual(wordLink.score, 2011)
        wordLink = WordLink(url: "http://hanein123.onion", text: "I am good thank you", wordCount: 13, numberOfVisits: 3, lastVisitTime: 100)
        XCTAssertEqual(wordLink.score, 3113)
        wordLink = WordLink(url: "http://hanein123.onion", text: "I am good thank you", wordCount: 10, numberOfVisits: 5, lastVisitTime: 700000000)
        XCTAssertEqual(wordLink.score, 700005010)
    }
    
    func testMergeWithWordLink() {
        var wordLink = WordLink(url: "http://hanein123.onion", text: "I am good thank you", wordCount: 1)
        var wordLink2 = WordLink(url: "http://hanein123.onion", text: "I am good thank you. How about you?", wordCount: 2)
        wordLink.mergeWith(wordLink: wordLink2)
        XCTAssertEqual(wordLink.url, "http://hanein123.onion")
        XCTAssertEqual(wordLink.text, "I am good thank you. How about you?")
        XCTAssertEqual(wordLink.wordCount, 2)
        
        wordLink = WordLink(url: "http://hanein123.onion", text: "I am good thank you", wordCount: 1)
        wordLink2 = WordLink(url: "http://hanein1234.onion", text: "I am good thank you. How about you?", wordCount: 2)
        wordLink.mergeWith(wordLink: wordLink2)
        XCTAssertEqual(wordLink.url, "http://hanein123.onion")
        XCTAssertEqual(wordLink.text, "I am good thank you. How about you?")
        XCTAssertEqual(wordLink.wordCount, 2)
    }
}
