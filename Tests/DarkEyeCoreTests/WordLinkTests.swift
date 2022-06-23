import XCTest
@testable import DarkEyeCore

final class WordLinkTests: TestsBase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testScore() {
        var wordLink = WordLink(url: "http://hanein123.onion", title: "Hanein News Forum" , text: "I am good thank you", wordCount: 1, numberOfVisits: 1, lastVisitTime: 10)
        XCTAssertEqual(wordLink.score, 1011)
        wordLink = WordLink(url: "http://hanein123.onion", title: "Hanein News Forum", text: "I am good thank you", wordCount: 1, numberOfVisits: 2, lastVisitTime: 10)
        XCTAssertEqual(wordLink.score, 2011)
        wordLink = WordLink(url: "http://hanein123.onion", title: "Hanein News Forum", text: "I am good thank you", wordCount: 13, numberOfVisits: 3, lastVisitTime: 100)
        XCTAssertEqual(wordLink.score, 3113)
        wordLink = WordLink(url: "http://hanein123.onion", title: "Hanein News Forum", text: "I am good thank you", wordCount: 10, numberOfVisits: 5, lastVisitTime: 700000000)
        XCTAssertEqual(wordLink.score, 700005010)
    }
     
    func testWordLinksWithSearchText() {
        let expectation = expectation(description: "found the `use` word")
        Link.numberOfProcessedLinks = 0
        crawler = Crawler()
        crawler.start()
#if os(Linux)
        let secondsDelay = 60.0
#else
        let secondsDelay = 40.0
#endif
        let countLimit = 1000
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 2.0) {
            if crawler.isExecuting == false {
                var wordLinks = WordLink.wordLinks(withSearchText: "use the", count: countLimit)
                let wordLinksCount = wordLinks.count
                if wordLinksCount > 1 {
                    //print("wordLinks 1: \(wordLinks.map { "\($0.url), score: \($0.score)" } )")
                    let illegalKey = Link.prefix + wordLinks[0].url
                    print("illegalKey: \(illegalKey)")
                    if var link: Link = database[illegalKey] {
                        link.illegal = true
                        link.save()
                    }
                    wordLinks = WordLink.wordLinks(withSearchText: "use the", count: countLimit)
                    //print("wordLinks 2: \(wordLinks.map { "\($0.url), score: \($0.score)" } )")
                    XCTAssertEqual(wordLinks.count, wordLinksCount - 1)
                    expectation.fulfill()
                } else {
                    XCTFail()
                }
            }
        }
        waitForExpectations(timeout: secondsDelay + 5, handler: nil)
    }
    
    func testMergeWordLinks() {
        var links = [WordLink(url: "http://hanein123.onion", title: "Hanein News Forum", text: "I am good thank you", wordCount: 1)]
        var links2 = [WordLink(url: "http://hanein123.onion", title: "Hanein News Forum", text: "I am good thank you. How about you?", wordCount: 2)]
        WordLink.merge(wordLinks: &links, withWordLinks: links2)
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0].url, "http://hanein123.onion")
        XCTAssertEqual(links[0].text, "I am good thank you. How about you?")
        XCTAssertEqual(links[0].wordCount, 2)
        
        links = [WordLink(url: "http://hanein123.onion", title: "Hanein News Forum", text: "I am good thank you", wordCount: 1)]
        links2 = [WordLink(url: "http://hanein1234.onion", title: "Hanein News Forum", text: "I am good thank you. How about you?", wordCount: 2)]
        WordLink.merge(wordLinks: &links, withWordLinks: links2)
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[0].url, "http://hanein123.onion")
        XCTAssertEqual(links[0].text, "I am good thank you")
        XCTAssertEqual(links[0].wordCount, 1)
        XCTAssertEqual(links[1].url, "http://hanein1234.onion")
        XCTAssertEqual(links[1].text, "I am good thank you. How about you?")
        XCTAssertEqual(links[1].wordCount, 2)
    }
    
    func testMergeWithWordLink() {
        var wordLink = WordLink(url: "http://hanein123.onion", title: "Hanein News Forum", text: "I am good thank you", wordCount: 1)
        var wordLink2 = WordLink(url: "http://hanein123.onion", title: "Hanein News Forum", text: "I am good thank you. How about you?", wordCount: 2)
        wordLink.mergeWith(wordLink: wordLink2)
        XCTAssertEqual(wordLink.url, "http://hanein123.onion")
        XCTAssertEqual(wordLink.text, "I am good thank you. How about you?")
        XCTAssertEqual(wordLink.wordCount, 2)
        
        wordLink = WordLink(url: "http://hanein123.onion", title: "Hanein News Forum", text: "I am good thank you", wordCount: 1)
        wordLink2 = WordLink(url: "http://hanein1234.onion", title: "Hanein News Forum", text: "I am good thank you. How about you?", wordCount: 2)
        wordLink.mergeWith(wordLink: wordLink2)
        XCTAssertEqual(wordLink.url, "http://hanein123.onion")
        XCTAssertEqual(wordLink.text, "I am good thank you. How about you?")
        XCTAssertEqual(wordLink.wordCount, 2)
    }
}
