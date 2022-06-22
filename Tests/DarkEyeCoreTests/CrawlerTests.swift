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
        let relunchedExpectation = expectation(description: "crawler relunched")
        crawler.start()
#if os(Linux)
        let secondsDelay = 30.0
#else
        let secondsDelay = 30.0
#endif
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay / 3) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay) {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 2.0) {
            crawler = Crawler()
            crawler.start()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 3.0) {
            if crawler.isExecuting {
                relunchedExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay + 4.0) {
            crawler.canRun = false
        }
        waitForExpectations(timeout: secondsDelay + 10, handler: nil)
    }
    
}
