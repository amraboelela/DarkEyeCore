import XCTest
@testable import DarkeyeCore

final class StringTests: TestsBase {
    
    override func asyncSetup() async {
        await super.asyncSetup()
    }
    
    override func asyncTearDown() async {
        await super.asyncTearDown()
        await Crawler.shared().stop()
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
    
    func testSliceFrom() {
        let token = "javascript:getInfo(1,'Info/99/something', 'City Hall',1, 99);"
            .slice(from: "'", to: "',")
        XCTAssertEqual(token, "Info/99/something")
        
        let string = "/search/search/redirect?search_term=war on ukrain&redirect_url=http://bafkad5xfa6zbzhyvczf24j4ppbc4ylcavgwnmkppccikejzbdxzxlad.onion/node/205669"
        XCTAssertEqual(string.slice(from: "redirect_url="), "http://bafkad5xfa6zbzhyvczf24j4ppbc4ylcavgwnmkppccikejzbdxzxlad.onion/node/205669")
    }
    
    func testOnionID() {
        var url = "http://hanein1.onion"
        var onionID = url.onionID
        XCTAssertEqual(onionID, "hanein1")
        url = "http://mama.hanein1.onion"
        onionID = url.onionID
        XCTAssertEqual(onionID, "hanein1")
    }
}
