import XCTest
@testable import DarkEyeCore

final class CrawlerTests: TestsBase, CrawlerDelegate {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        crawler.stop()
    }
    
    func testStart() {
        let runningExpectation = expectation(description: "crawler is running")
        crawler.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSLog("testing running")
            if crawler.canRun {
                runningExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCrawl() {
        let duckduckExpectation = expectation(description: "duckduck link is there")
        crawler.crawl()
#if os(Linux)
        let secondsDelay = 10.0
#else
        let secondsDelay = 5.0
#endif
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 2.0) {
            if let _: Link = database[Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion"] {
                //print("testCrawl passed after \(secondsDelay) seconds")
                duckduckExpectation.fulfill()
                print("Link.numberOfProcessedLinks: \(Link.numberOfProcessedLinks)")
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: secondsDelay + 5, handler: nil)
    }
    
    var stopped = false
    
    func crawlerStopped() {
        stopped = true
    }
    
    func testStop() {
        let stoppedExpectation = expectation(description: "crawler has stopped")
        crawler.delegate = self
        crawler.crawl()
        let timeDelay = 10.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            crawler.stop()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeDelay) {
            if !crawler.canRun && self.stopped {
                stoppedExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: timeDelay + 5.0, handler: nil)
    }
}
