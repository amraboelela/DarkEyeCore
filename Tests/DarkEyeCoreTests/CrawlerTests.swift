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
        let expectation = expectation(description: "duckduck link is there")
        crawler.start()
#if os(Linux)
        let secondsDelay = 30.0
#else
        let secondsDelay = 7.0
#endif
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay / 3) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay) {
            if crawler.isExecuting == false {
                if let _: Link = database[Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion"] {
                    print("testCrawl passed after \(secondsDelay) seconds")
                    expectation.fulfill()
                } else {
                    XCTFail()
                }
            }
        }
        waitForExpectations(timeout: secondsDelay + 10, handler: nil)
    }
    
}
