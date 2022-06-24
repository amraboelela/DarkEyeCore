import XCTest
@testable import DarkEyeCore

final class CrawlerTests: TestsBase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCrawl() {
        let duckduckExpectation = expectation(description: "duckduck link is there")
        crawler.start()
#if os(Linux)
        let secondsDelay = 60.0
#else
        let secondsDelay = 40.0
#endif
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 2.0) {
            if crawler.isExecuting == false {
                if let _: Link = database[Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion"] {
                    print("testCrawl passed after \(secondsDelay) seconds")
                    duckduckExpectation.fulfill()
                } else {
                    XCTFail()
                }
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: secondsDelay + 5, handler: nil)
    }
    
    func testRestart() {
        let stoppedExpectation = expectation(description: "crawler stopped")
        let relunchedExpectation = expectation(description: "crawler relunched")
        Crawler.restart()
#if os(Linux)
        let secondsDelay = 30.0
#else
        let secondsDelay = 30.0
#endif
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 1.0) {
            if !crawler.isExecuting {
                stoppedExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 2.0) {
            Crawler.restart()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 3.0) {
            if crawler.isExecuting {
                relunchedExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: secondsDelay + 10, handler: nil)
    }
    
}
