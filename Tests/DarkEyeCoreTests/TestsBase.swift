import XCTest
@testable import DarkEyeCore

class TestsBase: XCTestCase {
    
    override func setUp() {
        super.setUp()
        if database != nil {
            if database.db != nil {
                database.deleteDatabaseFromDisk()
            }
        }
        //usleep(1000000)
        let testRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "DarkEyeCoreTests/TestsBase.swift", with: "/")).path
        database = Database(parentPath: testRoot + "Library", name: "Database")
        crawler = Crawler()
    }
    
    override func tearDown() {
        super.tearDown()
        crawler.canRun = false
        usleep(1000000)
        database.deleteDatabaseFromDisk()
    }
    
}
