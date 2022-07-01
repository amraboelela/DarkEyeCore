import XCTest
@testable import DarkEyeCore

final class CrawlerTests: TestsBase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        crawler.stop()
    }
    
    func testCrawl() {
        let duckduckExpectation = expectation(description: "duckduck link is there")
        crawler.crawl()
#if os(Linux)
        let secondsDelay = 40.0
#else
        let secondsDelay = 30.0
#endif
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 2.0) {
            if let _: Link = database[Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion"] {
                print("testCrawl passed after \(secondsDelay) seconds")
                duckduckExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: secondsDelay + 5, handler: nil)
    }
    
    func testStop() {
        let stoppedExpectation = expectation(description: "crawler has stopped")
        crawler.crawl()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            crawler.stop()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if !crawler.running {
                stoppedExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRestart() {
        let runningExpectation = expectation(description: "crawler is runiing")
        let stoppedExpectation = expectation(description: "crawler stopped")
        Crawler.restart()
#if os(Linux)
        let secondsDelay = 30.0
#else
        let secondsDelay = 10.0
#endif
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 1.0) {
            if crawler.running {
                runningExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 2.0) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 3) {
            NSLog("testing stopped")
            if !crawler.running {
                stoppedExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: secondsDelay + 10, handler: nil)
    }
}
