//
//  DatabaseTests.swift
//  DarkEyeCoreTests
//
//  Created by: Amr Aboelela on 1/13/22.
//

import Foundation
import CoreFoundation
import XCTest
import SwiftLevelDB
@testable import DarkEyeCore

final class DatabaseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let testRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "DarkEyeCoreTests/DatabaseTests.swift", with: "/")).path
        database = LevelDB(parentPath: testRoot + "Library", name: "Database")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInit() async {
        XCTAssertNotNil(database)
        let parentPath = await database.parentPath
        XCTAssertNotNil(parentPath)
    }
    
    func testParentPath() async {
        await database.setParentPath("/path/to/Library")
        let dbPath = await database.dbPath
        XCTAssertEqual(dbPath, "/path/to/Library/Database")
    }
}
