import XCTest
@testable import DarkEyeCore

class TestsBase: XCTestCase {
    
    var mainUrl = "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
    
    override func setUp() {
        super.setUp()
        let testRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "DarkEyeCoreTests/TestsBase.swift", with: "/")).path
        database = Database(parentPath: testRoot + "Library", name: "Database")
    }
    
    override func tearDown() {
        super.tearDown()
        database.deleteDatabaseFromDisk()
    }
    
}
