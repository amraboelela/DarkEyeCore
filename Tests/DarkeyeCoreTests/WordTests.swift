import XCTest
@testable import DarkeyeCore

final class WordTests: TestsBase {
    
    override func asyncSetup() async {
        await super.asyncSetup()
    }
    
    override func asyncTearDown() async {
        await super.asyncTearDown()
    }
    
    func testWordsFromText() async {
        await asyncSetup()
        var words = Word.words(fromText: " Hey a of in the \n man   ")
        XCTAssertEqual(words.count, 5)
        XCTAssertEqual(words[0], "Hey")
        XCTAssertEqual(words[1], "a")
        XCTAssertEqual(words[2], "of")
        XCTAssertEqual(words[3], "in")
        XCTAssertEqual(words[4], "man")
        
        words = Word.words(fromText: "camelCaseIs TheCase YaSalam?")
        XCTAssertEqual(words.count, 5)
        XCTAssertEqual(words[0], "camel")
        XCTAssertEqual(words[1], "Case")
        XCTAssertEqual(words[2], "Is")
        XCTAssertEqual(words[3], "TheCase")
        XCTAssertEqual(words[4], "YaSalam")
        
        words = Word.words(fromText: "camelCaseIs TheCase YaSalam?", lowerCase: true)
        XCTAssertEqual(words.count, 5)
        XCTAssertEqual(words[0], "camel")
        XCTAssertEqual(words[1], "case")
        XCTAssertEqual(words[2], "is")
        XCTAssertEqual(words[3], "thecase")
        XCTAssertEqual(words[4], "yasalam")
        
        let link = Link(url: Link.mainUrls.first!)
        words = Word.words(fromText: await link.text())
        XCTAssertTrue(words.count > 3900)
        await asyncTearDown()
    }
    
    func testContextStringFromArray() async {
        await asyncSetup()
        var array = ["I", "went", "to", "college", "to", "go", "to", "the", "library"]
        var result = Word.contextStringFrom(array: array, atIndex: 5)
        XCTAssertEqual(result, "I went to college to go to the library")
        array = ["The", "Hidden", "Wiki", "Main", "Page", "From", "The", "Hidden", "Wiki", "Jump", "to", "navigation", "Jump", "to", "search", "Contents", "1", "Editor", "s", "picks", "2", "Volunteer", "3", "Introduction", "Points", "4", "Financial", "Services", "5", "Commercial", "Services", "6", "Domain", "Services", "7", "Anonymity", "Security", "8", "Darknet", "versions", "of", "popular", "sites", "9", "Blogs", "Essays", "News", "Sites", "10", "Email", "Messaging", "11", "Social", "Networks", "12", "Forums", "Boards", "Chats", "13", "Whistleblowing", "14", "H", "P", "A", "W", "V", "C", "15", "Hosting", "website", "developing", "16", "File", "Uploaders", "17", "Audio", "Radios", "on", "Tor", "18", "Videos", "Movies", "T", "V", "Games", "19", "Books", "20", "Drugs", "21", "Erotica", "21", "1", "Noncommercial", "E", "21", "2", "Commercial", "E", "22", "Uncategorized", "23", "Non", "English", "23", "1", "Brazilian", "23", "2", "Finnish", "Suomi", "23", "3", "French", "Français", "23", "4", "German", "Deutsch", "23", "5", "Greek", "ελληνικά", "23", "6", "Italian", "Italiano", "23", "7", "Japanese", "日本語", "23", "8", "Korean", "한국어", "23", "9", "Chinese", "中国語", "23", "10", "Polish", "Polski", "23", "11", "Russian", "Русский", "23", "12", "Spanish", "Español", "23", "13", "Portuguese", "Português", "23", "14", "Swedish", "Svenska", "23", "15", "Turkish", "Türk", "24", "Hidden", "Services", "Other", "Protocols", "25", "P2", "P", "File", "Sharing", "25", "1", "Chat", "centric", "services", "25", "1", "1", "Defunct", "I", "R", "C", "services", "for", "archive", "purposes", "25", "1", "2", "S", "I", "L", "C", "25", "1", "3", "X", "M", "P", "P", "formerly", "Jabber", "25", "1", "4", "Tor", "Chat", "Addresses", "26", "S", "F", "T", "P", "S", "S", "H", "File", "Transfer", "Protocol", "26", "1", "Onion", "Cat", "Addresses", "26", "2", "Bitcoin", "Seeding", "27", "Dead", "Hidden", "Services", "Welcome", "to", "The", "Hidden", "Wiki", "Our", "official", "Hidden", "Wiki", "url", "in", "2022", "is", "http", "onion", "Add", "it", "to", "bookmarks", "and", "spread", "it", "The", "Official", "Hidden", "Wiki", "2022", "contest", "is", "O", "N", "Now", "You", "can", "earn", "F", "R", "E", "E", "M", "O", "N", "E", "Y", "with", "the", "Hidden", "Wiki", "Click", "H", "E", "R", "E", "to", "learn", "how", "Editor", "s", "picks", "Pick", "a", "random", "page", "from", "the", "article", "index", "and", "replace", "one", "of", "these", "slots", "with", "it", "The", "Matrix", "Very", "nice", "to", "read", "How", "to", "Exit", "the", "Matrix", "Learn", "how", "to", "Protect", "yourself", "and"]
        result = Word.contextStringFrom(array: array, atIndex: 5)
        XCTAssertEqual(result, "The Hidden Wiki Main Page From The Hidden Wiki Jump to navigation Jump to search Contents 1 Editor s picks 2")
        result = Word.contextStringFrom(array: array, atIndex: 50)
        XCTAssertEqual(result, "of popular sites 9 Blogs Essays News Sites 10 Email Messaging 11 Social Networks 12 Forums Boards Chats 13 Whistleblowing 14")
        await asyncTearDown()
    }
    
    func testAllowedWordsArray() {
        XCTAssertFalse(Word.allowed(wordsArray: ["credit", "cards"]))
        XCTAssertFalse(Word.allowed(wordsArray: ["credit", "card"]))
        XCTAssertTrue(Word.allowed(wordsArray: ["credits", "card"]))
        XCTAssertFalse(Word.allowed(wordsArray: ["bitcoin", "private", "key"]))
    }
}
