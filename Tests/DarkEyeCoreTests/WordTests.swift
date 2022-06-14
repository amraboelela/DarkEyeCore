import XCTest
@testable import DarkEyeCore

final class WordTests: TestsBase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testIndexLink() {
        var link = Link(url: "http://hanein123.onion", lastProcessTime: 0, numberOfVisits: 0, lastVisitTime: 0, html: "<html><body><p>I went to college to go to the library</p></body></html>")
        Word.index(link: link)
        if let word: Word = database[Word.prefix + "library"] {
            XCTAssertTrue(word.links[0].text.lowercased().contains("library"))
            XCTAssertEqual(word.links[0].url, "http://hanein123.onion")
        } else {
            XCTFail()
        }
        if let _: Word = database[Word.prefix + "body"] {
            XCTFail()
        }
        link = Link(
            url: "http://hanein123.onion",
            lastProcessTime: 0,
            numberOfVisits: 0,
            lastVisitTime: 0,
            html: nil
        )
        link.load()
        Word.index(link: link)
        if let word: Word = database[Word.prefix + "bitcoin"] {
            XCTAssertTrue(word.links[0].text.lowercased().contains("bitcoin"))
            XCTAssertEqual(word.links[0].url, "http://hanein123.onion")
        } else {
            XCTFail()
        }
        if let word: Word = database[Word.prefix + "the"] {
            XCTAssertTrue(word.links[0].text.lowercased().contains("the"))
            XCTAssertEqual(word.links[0].url, "http://hanein123.onion")
        } else {
            XCTFail()
        }
        if let word: Word = database[Word.prefix + "hidden"] {
            XCTAssertTrue(word.links[0].text.lowercased().contains("hidden"))
            XCTAssertEqual(word.links[0].url, "http://hanein123.onion")
        } else {
            XCTFail()
        }
        if let _: Word = database[Word.prefix + "a"] {
            XCTFail()
        }
        if let _: Word = database[Word.prefix + "in"] {
            XCTFail()
        }
        if let _: Word = database[Word.prefix + "of"] {
            XCTFail()
        }
        if let _: Word = database[Word.prefix + "to"] {
            XCTFail()
        }
    }
    
    func testWordsFromText() {
        var words = Word.words(fromText: " Hey a of in the \n man   ")
        XCTAssertEqual(words.count, 6)
        XCTAssertEqual(words[0], "Hey")
        XCTAssertEqual(words[1], "a")
        XCTAssertEqual(words[2], "of")
        XCTAssertEqual(words[3], "in")
        XCTAssertEqual(words[4], "the")
        XCTAssertEqual(words[5], "man")
        
        var link = Link(url: "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page")
        link.load()
        words = Word.words(fromText: link.text)
        XCTAssertTrue(words.count > 4810)
        print("testWordsFromText words: \(words)")
    }
    
    func testContextStringFromArray() {
        var array = ["I", "went", "to", "college", "to", "go", "to", "the", "library"]
        var result = Word.contextStringFrom(array: array, atIndex: 5)
        XCTAssertEqual(result, "I went to college to go to the library")
        array = ["The", "Hidden", "Wiki", "Main", "Page", "From", "The", "Hidden", "Wiki", "Jump", "to", "navigation", "Jump", "to", "search", "Contents", "1", "Editor", "s", "picks", "2", "Volunteer", "3", "Introduction", "Points", "4", "Financial", "Services", "5", "Commercial", "Services", "6", "Domain", "Services", "7", "Anonymity", "Security", "8", "Darknet", "versions", "of", "popular", "sites", "9", "Blogs", "Essays", "News", "Sites", "10", "Email", "Messaging", "11", "Social", "Networks", "12", "Forums", "Boards", "Chats", "13", "Whistleblowing", "14", "H", "P", "A", "W", "V", "C", "15", "Hosting", "website", "developing", "16", "File", "Uploaders", "17", "Audio", "Radios", "on", "Tor", "18", "Videos", "Movies", "T", "V", "Games", "19", "Books", "20", "Drugs", "21", "Erotica", "21", "1", "Noncommercial", "E", "21", "2", "Commercial", "E", "22", "Uncategorized", "23", "Non", "English", "23", "1", "Brazilian", "23", "2", "Finnish", "Suomi", "23", "3", "French", "Français", "23", "4", "German", "Deutsch", "23", "5", "Greek", "ελληνικά", "23", "6", "Italian", "Italiano", "23", "7", "Japanese", "日本語", "23", "8", "Korean", "한국어", "23", "9", "Chinese", "中国語", "23", "10", "Polish", "Polski", "23", "11", "Russian", "Русский", "23", "12", "Spanish", "Español", "23", "13", "Portuguese", "Português", "23", "14", "Swedish", "Svenska", "23", "15", "Turkish", "Türk", "24", "Hidden", "Services", "Other", "Protocols", "25", "P2", "P", "File", "Sharing", "25", "1", "Chat", "centric", "services", "25", "1", "1", "Defunct", "I", "R", "C", "services", "for", "archive", "purposes", "25", "1", "2", "S", "I", "L", "C", "25", "1", "3", "X", "M", "P", "P", "formerly", "Jabber", "25", "1", "4", "Tor", "Chat", "Addresses", "26", "S", "F", "T", "P", "S", "S", "H", "File", "Transfer", "Protocol", "26", "1", "Onion", "Cat", "Addresses", "26", "2", "Bitcoin", "Seeding", "27", "Dead", "Hidden", "Services", "Welcome", "to", "The", "Hidden", "Wiki", "Our", "official", "Hidden", "Wiki", "url", "in", "2022", "is", "http", "onion", "Add", "it", "to", "bookmarks", "and", "spread", "it", "The", "Official", "Hidden", "Wiki", "2022", "contest", "is", "O", "N", "Now", "You", "can", "earn", "F", "R", "E", "E", "M", "O", "N", "E", "Y", "with", "the", "Hidden", "Wiki", "Click", "H", "E", "R", "E", "to", "learn", "how", "Editor", "s", "picks", "Pick", "a", "random", "page", "from", "the", "article", "index", "and", "replace", "one", "of", "these", "slots", "with", "it", "The", "Matrix", "Very", "nice", "to", "read", "How", "to", "Exit", "the", "Matrix", "Learn", "how", "to", "Protect", "yourself", "and"]
        result = Word.contextStringFrom(array: array, atIndex: 5)
        XCTAssertEqual(result, "The Hidden Wiki Main Page From The Hidden Wiki Jump to navigation Jump to search Contents 1 Editor s picks 2")
        result = Word.contextStringFrom(array: array, atIndex: 50)
        XCTAssertEqual(result, "of popular sites 9 Blogs Essays News Sites 10 Email Messaging 11 Social Networks 12 Forums Boards Chats 13 Whistleblowing 14")
    }
    
    func testMergeWithWord() {
        var word = Word(links: [WordLink(url: "http://hanein123.onion", text: "I am good thank you", wordCount: 1)])
        var word2 = Word(links: [WordLink(url: "http://hanein123.onion", text: "I am good thank you. How about you?", wordCount: 2)])
        word.mergeWith(word: word2)
        XCTAssertEqual(word.links.count, 1)
        XCTAssertEqual(word.links[0].url, "http://hanein123.onion")
        XCTAssertEqual(word.links[0].text, "I am good thank you. How about you?")
        XCTAssertEqual(word.links[0].wordCount, 2)
        
        word = Word(links: [WordLink(url: "http://hanein123.onion", text: "I am good thank you", wordCount: 1)])
        word2 = Word(links: [WordLink(url: "http://hanein1234.onion", text: "I am good thank you. How about you?", wordCount: 2)])
        word.mergeWith(word: word2)
        XCTAssertEqual(word.links.count, 2)
        XCTAssertEqual(word.links[0].url, "http://hanein123.onion")
        XCTAssertEqual(word.links[0].text, "I am good thank you")
        XCTAssertEqual(word.links[0].wordCount, 1)
        XCTAssertEqual(word.links[1].url, "http://hanein1234.onion")
        XCTAssertEqual(word.links[1].text, "I am good thank you. How about you?")
        XCTAssertEqual(word.links[1].wordCount, 2)
    }
}
