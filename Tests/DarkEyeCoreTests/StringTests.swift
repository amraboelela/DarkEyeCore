import XCTest
@testable import DarkEyeCore

final class StringTests: TestsBase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCamelCaseToWords() {
        var words = "IRC".camelCaseWords
        XCTAssertEqual(words.count, 1)
        words = "ImRcHey".camelCaseWords
        XCTAssertEqual(words.count, 1)
        words = "ImRHey".camelCaseWords
        XCTAssertEqual(words.count, 1)
        words = "PayPal".camelCaseWords
        XCTAssertEqual(words.count, 1)
        words = "PayPalIsGood".camelCaseWords
        XCTAssertEqual(words.count, 4)
    }
    
    func testFromArray() {
        let array = ["I", "went", "to", "college", "to", "go", "to", "the", "library"]
        var result = String.from(array: array, startIndex: 2, endIdnex: 4)
        XCTAssertEqual(result, "to college to")
        result = String.from(array: array, startIndex: 5, endIdnex: 8)
        XCTAssertEqual(result, "go to the library")
    }
    
}
