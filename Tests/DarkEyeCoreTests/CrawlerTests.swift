import XCTest
@testable import DarkEyeCore

final class CrawlerTests: TestsBase, CrawlerDelegate {
    
    override func asyncSetup() async {
        await super.asyncSetup()
    }
    
    override func asyncTearDown() async {
        await super.asyncTearDown()
        try? await Crawler.shared().stop()
    }
    
    func testStart() async {
        await asyncSetup()
        let runningExpectation = expectation(description: "crawler is running")
        let crawler = try! await Crawler.shared()
        await crawler.start()
        print("crawler.canRun: \(crawler.canRun)")
        try? await Task.sleep(seconds: 1.0)
        NSLog("testing running")
        print("crawler.canRun: \(crawler.canRun)")
        if crawler.canRun {
            runningExpectation.fulfill()
        } else {
            XCTFail()
        }
#if os(Linux)
        waitForExpectations(timeout: 5, handler: nil)
#else
        await waitForExpectations(timeout: 5, handler: nil)
#endif
        await asyncTearDown()
    }
    
    func testCrawl() async {
        await asyncSetup()
        let duckduckExpectation = expectation(description: "duckduck link is there")
        let crawler = try! await Crawler.shared()
        await crawler.crawl()
        let secondsDelay = 5.0
        try? await Task.sleep(seconds: secondsDelay)
        crawler.canRun = false
        try? await Task.sleep(seconds: 2.0)
        if let _: Link = await database.valueForKey(Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion") {
            //print("testCrawl passed after \(secondsDelay) seconds")
            duckduckExpectation.fulfill()
            print("Link.numberOfProcessedLinks: \(Link.numberOfProcessedLinks)")
        } else {
            XCTFail()
        }
#if os(Linux)
        waitForExpectations(timeout: secondsDelay + 5, handler: nil)
#else
        await waitForExpectations(timeout: secondsDelay + 5, handler: nil)
#endif
        await asyncTearDown()
    }
    
    var stopped = false
    
    func crawlerStopped() {
        stopped = true
    }
    
    func testStop() async {
        await asyncSetup()
        let stoppedExpectation = expectation(description: "crawler has stopped")
        let crawler = try! await Crawler.shared()
        crawler.delegate = self
        await crawler.crawl()
        let timeDelay = 8.0
        try? await Task.sleep(seconds: 2.0)
        await crawler.stop()
        try? await Task.sleep(seconds: timeDelay)
        if !crawler.canRun && self.stopped {
            stoppedExpectation.fulfill()
        } else {
            XCTFail()
        }
#if os(Linux)
        waitForExpectations(timeout: timeDelay + 5.0, handler: nil)
#else
        await waitForExpectations(timeout: timeDelay + 5.0, handler: nil)
#endif
        await asyncTearDown()
    }
}
