import XCTest
@testable import DarkEyeCore

final class WordLinkTests: TestsBase {
    
    override func asyncSetup() async {
        await super.asyncSetup()
    }
    
    override func asyncTearDown() async {
        await super.asyncTearDown()
    }
    
    func testHashLink() async {
        await asyncSetup()
        var url = "http://hanein123.onion"
        var link = Link(url: url)
        try? await link.save()
        var urlHash = url.hashBase32(numberOfDigits: 12)
        var wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1, numberOfVisits: 1, lastVisitTime: 10)
        var link2 = await wordLink.hashLink()?.link()
        XCTAssertEqual(link2?.hash, "ar7t3hfhcdxg")
        
        url = Link.mainUrl
        link = Link(url: url)
        try? await link.save()
        urlHash = url.hashBase32(numberOfDigits: 12)
        wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1, numberOfVisits: 1, lastVisitTime: 10)
        link2 = await wordLink.hashLink()?.link()
        XCTAssertEqual(link2?.hash, "9c2c4863y3x7")
        await asyncTearDown()
    }
    
    func testScore() async {
        await asyncSetup()
        let urlHash = "http://hanein123.onion".hashBase32(numberOfDigits: 12)
        var wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1, numberOfVisits: 1, lastVisitTime: 10)
        XCTAssertEqual(wordLink.score, 1011)
        wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 1, numberOfVisits: 2, lastVisitTime: 10)
        XCTAssertEqual(wordLink.score, 2011)
        wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 13, numberOfVisits: 3, lastVisitTime: 100)
        XCTAssertEqual(wordLink.score, 3113)
        wordLink = WordLink(urlHash: urlHash, word: "good", text: "I am good thank you", wordCount: 10, numberOfVisits: 5, lastVisitTime: 700000000)
        XCTAssertEqual(wordLink.score, 700005010)
        await asyncTearDown()
    }
     
    func testWordLinksWithSearchText() async {
        await asyncSetup()
        Link.numberOfProcessedLinks = 0
        let crawler = try! await Crawler.shared()
        await crawler.start()
        let secondsDelay = 10.0
        let countLimit = 1000
        try? await Task.sleep(seconds: secondsDelay)
        crawler.canRun = false
        try? await Task.sleep(seconds: 2.0)
        var wordLinks = await WordLink.wordLinks(withSearchText: "to jump", count: countLimit)
        var wordLinksCount = wordLinks.count
        print("wordLinksCount 1: \(wordLinksCount)")
        print("wordLinks 1: \(wordLinks)")
        if wordLinksCount > 0 {
            for wordLink in wordLinks {
                XCTAssertEqual(wordLink.word, "jump")
            }
        } else {
            XCTFail()
        }
        try? await Task.sleep(seconds: 1.0)
        wordLinks = await WordLink.wordLinks(withSearchText: "hidden wiki", count: countLimit)
        wordLinksCount = wordLinks.count
        print("wordLinksCount 2: \(wordLinksCount)")
        print("wordLinks 2: \(wordLinks)")
        if wordLinksCount >= 1 {
            let blockedKey = HashLink.prefix + wordLinks[0].urlHash
            print("blockedKey: \(blockedKey)")
            if let hashLink: HashLink = await database.valueForKey(blockedKey) {
                var link = await hashLink.link()
                link.blocked = true
                try? await link.save()
            }
            wordLinks = await WordLink.wordLinks(withSearchText: "hidden wiki", count: countLimit)
            XCTAssertEqual(wordLinks.count, wordLinksCount - 1)
        } else {
            XCTFail()
        }
        await asyncTearDown()
    }
    
    func testMergeWordLinks() async {
        await asyncSetup()
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
        await asyncTearDown()
    }
    
    func testMergeWithWordLink() async {
        await asyncSetup()
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
        await asyncTearDown()
    }
}
