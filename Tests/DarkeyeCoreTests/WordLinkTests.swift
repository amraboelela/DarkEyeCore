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
        var link = Link(url: Global.mainUrls.first!)
        var result  = await WordLink.index(link: link)
        XCTAssertEqual(result, .complete)
        if let word: WordLink = await database.value(forKey: WordLink.prefix + "hidden-" + Global.mainUrls.first!) {
            XCTAssertTrue(word.text.lowercased().contains("hidden"))
            XCTAssertEqual(word.url, Global.mainUrls.first!)
        } else {
            XCTFail()
        }
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "body-" + Global.mainUrls.first!) {
            XCTFail()
        }
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "a-" + Global.mainUrls.first!) {
            XCTFail()
        }
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "in-" + Global.mainUrls.first!) {
            XCTFail()
        }
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "of-" + Global.mainUrls.first!) {
            XCTFail()
        }
        if let _: WordLink = await database.value(forKey: WordLink.prefix + "to-" + Global.mainUrls.first!) {
            XCTFail()
        }
        
        link = Link(url: "http://kukuwawa.onion")
        result  = await WordLink.index(link: link)
        XCTAssertEqual(result, .complete)
        await asyncTearDown()
    }
    
   func testWordLinksWithSearchText() async {
       await asyncSetup()
       let crawler = await Crawler.shared()
       await crawler.start()
       let secondsDelay = 10.0
       let countLimit = 1000
       try? await Task.sleep(seconds: secondsDelay)
       crawler.canRun = false
       try? await Task.sleep(seconds: 2.0)
       var wordLinks = await WordLink.wordLinks(withSearchText: "to wiki", count: countLimit)
       var wordLinksCount = wordLinks.count
       print("wordLinksCount 1: \(wordLinksCount)")
       print("wordLinks 1: \(wordLinks)")
       if wordLinksCount > 0 {
           for wordLink in wordLinks {
               XCTAssertNotNil(wordLink.word.range(of: "wiki"))
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
