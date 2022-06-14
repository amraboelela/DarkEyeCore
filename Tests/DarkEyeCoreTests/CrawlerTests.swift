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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            crawler.canRun = false
        }
        let secondsDelay = 7.0
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
        waitForExpectations(timeout: 8, handler: nil)
    }
    
}
