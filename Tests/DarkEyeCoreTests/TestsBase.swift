import XCTest
@testable import DarkEyeCore

class TestsBase: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let testRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "DarkEyeCoreTests/TestsBase.swift", with: "/")).path
        database = Database(parentPath: testRoot + "Library", name: "Database")
        crawler.canRun = true
    }
    
    override func tearDown() {
        super.tearDown()
        database.deleteDatabaseFromDisk()
    }
    
}
