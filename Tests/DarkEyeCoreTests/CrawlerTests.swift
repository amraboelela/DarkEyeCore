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
        crawler.crawl()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            if crawler.thread?.isExecuting == false {
                XCTAssertFalse(crawler.thread?.isExecuting == true)
                if let _: Link = database[Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion"] {
                    print("testCrawl passed after 5 seconds")
                    expectation.fulfill()
                } else {
                    XCTFail()
                }
            }
        }
        waitForExpectations(timeout: 8, handler: nil)
    }
    
}
