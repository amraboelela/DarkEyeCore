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
        let testRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "DarkEyeCoreTests/DatabaseTests.swift", with: "/")).path
        database = Database(parentPath: testRoot + "Library", name: "Database")
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
