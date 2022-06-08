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
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInit() {
        let database = Database(name: "Database")
        XCTAssertNotNil(database)
        XCTAssertNotNil(database.parentPath)
    }
    
    func testParentPath() {
        let database = Database(name: "Database")
        database.parentPath = "/path/to/Library"
        XCTAssertEqual(database.dbPath, "/path/to/Library/Database")
    }
}
