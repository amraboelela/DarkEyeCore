import XCTest
@testable import DarkEyeCore

final class WordLinkTests: TestsBase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testHashLink() {
        var url = "http://hanein123.onion"
        var link = Link(url: url)
        link.save()
        var urlHash = url.hashBase32(numberOfDigits: 12)
        var wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1, numberOfVisits: 1, lastVisitTime: 10)
        var link2 = try! XCTUnwrap(wordLink.hashLink?.link)
        XCTAssertEqual(link2.hash, "ar7t3hfhcdxg")
        
        url = Link.mainUrl
        link = Link(url: url)
        link.save()
        urlHash = url.hashBase32(numberOfDigits: 12)
        wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1, numberOfVisits: 1, lastVisitTime: 10)
        link2 = try! XCTUnwrap(wordLink.hashLink?.link)
        XCTAssertEqual(link2.hash, "9c2c4863y3x7")
    }
    
    func testScore() {
        let urlHash = "http://hanein123.onion".hashBase32(numberOfDigits: 12)
        var wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1, numberOfVisits: 1, lastVisitTime: 10)
        XCTAssertEqual(wordLink.score, 1011)
        wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1, numberOfVisits: 2, lastVisitTime: 10)
        XCTAssertEqual(wordLink.score, 2011)
        wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 13, numberOfVisits: 3, lastVisitTime: 100)
        XCTAssertEqual(wordLink.score, 3113)
        wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 10, numberOfVisits: 5, lastVisitTime: 700000000)
        XCTAssertEqual(wordLink.score, 700005010)
    }
     
    func testWordLinksWithSearchText() {
        let expectation = expectation(description: "found the `use` word")
        Link.numberOfProcessedLinks = 0
        crawler.start()
        let secondsDelay = 30.0
        let countLimit = 1000
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 2.0) {
            let wordLinks = WordLink.wordLinks(withSearchText: "ac abortion", count: countLimit)
            let wordLinksCount = wordLinks.count
            print("wordLinksCount 1: \(wordLinksCount)")
            print("wordLinks 1: \(wordLinks)")
            if wordLinksCount > 0 {
                for wordLink in wordLinks {
                    XCTAssertEqual(wordLink.word, "abortion")
                }
            } else {
                XCTFail()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 3.0) {
            var wordLinks = WordLink.wordLinks(withSearchText: "accepted Abortion", count: countLimit)
            let wordLinksCount = wordLinks.count
            print("wordLinksCount 2: \(wordLinksCount)")
            print("wordLinks 2: \(wordLinks)")
            if wordLinksCount > 1 {
                let blockedKey = HashLink.prefix + wordLinks[0].urlHash
                print("blockedKey: \(blockedKey)")
                if let hashLink: HashLink = database[blockedKey] {
                    var link = hashLink.link
                    link.blocked = true
                    link.save()
                }
                wordLinks = WordLink.wordLinks(withSearchText: "accepted Abortion", count: countLimit)
                XCTAssertEqual(wordLinks.count, wordLinksCount - 1)
                expectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: secondsDelay + 10, handler: nil)
    }
    
    func testMergeWordLinks() {
        let urlHash = "http://hanein123.onion".hashBase32(numberOfDigits: 12)
        var links = [WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1)]
        var links2 = [WordLink(urlHash: urlHash, word: "how", text: "I am good thank you. How about you?", wordCount: 2)]
        WordLink.merge(wordLinks: &links, withWordLinks: links2)
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0].urlHash, urlHash)
        XCTAssertEqual(links[0].text, "I am good thank you...I am good thank you. How about you?")
        XCTAssertEqual(links[0].wordCount, 3)
        
        links = [WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1)]
        let urlHash2 = "http://hanein1234.onion".hashBase32(numberOfDigits: 12)
        links2 = [WordLink(urlHash: urlHash2, word: "good", text: "I am good thank you. How about you?", wordCount: 2)]
        WordLink.merge(wordLinks: &links, withWordLinks: links2)
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[0].urlHash, urlHash)
        XCTAssertEqual(links[0].text, "I am good thank you")
        XCTAssertEqual(links[0].wordCount, 1)
        XCTAssertEqual(links[1].urlHash, urlHash2)
        XCTAssertEqual(links[1].text, "I am good thank you. How about you?")
        XCTAssertEqual(links[1].wordCount, 2)
    }
    
    func testMergeWithWordLink() {
        let urlHash = "http://hanein123.onion".hashBase32(numberOfDigits: 12)
        var wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1)
        var wordLink2 = WordLink(urlHash: urlHash, word: "how", text: "I am good thank you. How about you?", wordCount: 2)
        wordLink.mergeWith(wordLink: wordLink2)
        XCTAssertEqual(wordLink.urlHash, urlHash)
        XCTAssertEqual(wordLink.text, "I am good thank you...I am good thank you. How about you?")
        XCTAssertEqual(wordLink.wordCount, 3)
        
        wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1)
        let urlHash2 = "http://hanein1234.onion".hashBase32(numberOfDigits: 12)
        wordLink2 = WordLink(urlHash: urlHash2, word: "good", text: "I am good thank you. How about you?", wordCount: 2)
        wordLink.mergeWith(wordLink: wordLink2)
        XCTAssertEqual(wordLink.urlHash, urlHash)
        XCTAssertEqual(wordLink.text, "I am good thank you")
        XCTAssertEqual(wordLink.wordCount, 1)
        
        wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1)
        wordLink2 = WordLink(urlHash: urlHash, word: "how", text: "I am good thank you", wordCount: 2)
        wordLink.mergeWith(wordLink: wordLink2)
        XCTAssertEqual(wordLink.urlHash, urlHash)
        XCTAssertEqual(wordLink.text, "I am good thank you")
        XCTAssertEqual(wordLink.wordCount, 3)
    }
}
