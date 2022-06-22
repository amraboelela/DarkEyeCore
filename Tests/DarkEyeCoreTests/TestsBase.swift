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
        let testRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "DarkEyeCoreTests/TestsBase.swift", with: "/")).path
        database = Database(parentPath: testRoot + "Library", name: "Database")
    }
    
    override func tearDown() {
        super.tearDown()
        database.deleteDatabaseFromDisk()
        crawler.canRun = false
    }
    
}
