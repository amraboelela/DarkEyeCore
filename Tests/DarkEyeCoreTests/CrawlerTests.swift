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
        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
            crawler.canRun = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if crawler.thread?.isExecuting == false {
                XCTAssertFalse(crawler.thread?.isExecuting == true)
                if let _: Link = database[Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion"] {
                    print("testCrawl passed after 30 seconds")
                    expectation.fulfill()
                } else {
                    XCTFail()
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
            XCTAssertFalse(crawler.thread?.isExecuting == true)
            if let _: Link = database[Link.prefix + "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion"] {
                expectation.fulfill()
                print("testCrawl passed after 60 seconds")
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 100, handler: nil)
    }
    
}
