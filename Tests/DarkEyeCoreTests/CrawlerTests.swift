import XCTest
@testable import DarkEyeCore

final class CrawlerTests: TestsBase, CrawlerDelegate {
    
    override func asyncSetup() async {
        await super.asyncSetup()
    }
    
    override func asyncTearDown() async {
        await super.asyncTearDown()
        await Crawler.shared().stop()
    }
    
    func testStart() async {
        await asyncSetup()
        let crawler = await Crawler.shared()
        await crawler.start()
        print("crawler.canRun: \(crawler.canRun)")
        try? await Task.sleep(seconds: 1.0)
        NSLog("testing running")
        print("crawler.canRun: \(crawler.canRun)")
        if !crawler.canRun {
            XCTFail()
        }
        await asyncTearDown()
    }
    
    func testCrawl() async {
        await asyncSetup()
        let crawler = await Crawler.shared()
        await crawler.crawl()
        let secondsDelay = 5.0
        try? await Task.sleep(seconds: secondsDelay)
        crawler.canRun = false
        try? await Task.sleep(seconds: 2.0)
        if let _: Link = await database.value(forKey: Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion") {
            //print("testCrawl passed after \(secondsDelay) seconds")
            //duckduckExpectation.fulfill()
            print("Link.numberOfIndexedLinks: \(Link.numberOfIndexedLinks)")
        } else {
            XCTFail()
        }
        //waitForExpectations(timeout: secondsDelay + 5, handler: nil)
        await asyncTearDown()
    }
    
    var stopped = false
    
    func crawlerStopped() {
        stopped = true
    }
    
    func testStop() async {
        await asyncSetup()
        let crawler = await Crawler.shared()
        crawler.delegate = self
        await crawler.crawl()
        let timeDelay = 8.0
        try? await Task.sleep(seconds: 2.0)
        await crawler.stop()
        try? await Task.sleep(seconds: timeDelay)
        if crawler.canRun || !self.stopped {
            XCTFail()
        }
        await asyncTearDown()
    }
}
