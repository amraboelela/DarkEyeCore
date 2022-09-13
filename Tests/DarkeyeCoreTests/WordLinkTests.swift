import XCTest
@testable import DarkeyeCore

final class WordLinkTests: TestsBase {
    
    override func asyncSetup() async {
        await super.asyncSetup()
    }
    
    override func asyncTearDown() async {
        await super.asyncTearDown()
    }
    
    func testIndexLink() async {
        await asyncSetup()
        var link = Link(url: Global.mainUrl)
        var result  = await WordLink.index(link: link)
        XCTAssertEqual(result, .complete)
        if let word: WordLink = await database.value(forKey: WordLink.prefix + "hidden-" + Global.mainUrl) {
            XCTAssertTrue(word.text.lowercased().contains("hidden"))
            XCTAssertEqual(word.url, Global.mainUrl)
        } else {
            XCTFail()
        }
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "body-" + Global.mainUrl) {
            XCTFail()
        }
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "a-" + Global.mainUrl) {
            XCTFail()
        }
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "in-" + Global.mainUrl) {
            XCTFail()
        }
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "of-" + Global.mainUrl) {
            XCTFail()
        }
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "to-" + Global.mainUrl) {
            XCTFail()
        }
        
        link = Link(url: "http://kukuwawa.onion")
        result  = await WordLink.index(link: link)
        XCTAssertEqual(result, .complete)
        await asyncTearDown()
    }
    
   func testWordLinksWithSearchText() async {
       await asyncSetup()
       Link.numberOfProcessedLinks = 0
       let crawler = await Crawler.shared()
       await crawler.start()
       let secondsDelay = 10.0
       let countLimit = 1000
       try? await Task.sleep(seconds: secondsDelay)
       crawler.canRun = false
       try? await Task.sleep(seconds: 2.0)
       var wordLinks = await WordLink.wordLinks(withSearchText: "to print", count: countLimit)
       var wordLinksCount = wordLinks.count
       print("wordLinksCount 1: \(wordLinksCount)")
       print("wordLinks 1: \(wordLinks)")
       if wordLinksCount > 0 {
           for wordLink in wordLinks {
               XCTAssertEqual(wordLink.word, "print")
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
           let blockedKey = Site.prefix + wordLinks[0].url.onionID
           print("blockedKey: \(blockedKey)")
           if var site: Site = await database.value(forKey: blockedKey) {
               //var link = await hashLink.link()
               site.blocked = true
               await site.save()
           }
           wordLinks = await WordLink.wordLinks(withSearchText: "hidden wiki", count: countLimit)
           //print("wordLinks: \(wordLinks)")
           XCTAssertEqual(wordLinks.count, 0)
       } else {
           XCTFail()
       }
       await asyncTearDown()
   }
}
