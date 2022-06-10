//
//  DatabaseTests.swift
//  DarkEyeCoreTests
//
//  Created by: Amr Aboelela on 1/13/22.
//

import Foundation
import CoreFoundation
import XCTest
@testable import DarkEyeCore

final class DatabaseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let packageRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "Tests/DarkEyeCoreTests/DatabaseTests.swift", with: "")).path
        database = Database(parentPath: packageRoot + "Library", name: "Database")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInit() {
        XCTAssertNotNil(database)
        XCTAssertNotNil(database.parentPath)
    }
    
    func testParentPath() {
        database.parentPath = "/path/to/Library"
        XCTAssertEqual(database.dbPath, "/path/to/Library/Database")
    }
}
