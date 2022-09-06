//
//  WordLink.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/10/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation

public enum WordIndexingStatus {
    case complete // finished all the words up to 500 word
    case ended    // ended as it can't run
    case failed
}

public struct WordLink: Codable, Hashable, Sendable {
    public static let prefix = "wordlink-"

    public var word: String
    public var url: String
    public var text: String
    public var wordCount: Int
    public var numberOfVisits: Int = 0
    public var lastVisitTime: Int = 0
    
    // MARK: - Accessors
    
    var score: Int {
        return numberOfVisits * 1000 + wordCount + lastVisitTime
    }
    
    // MARK: - Indexing
    
    public static func index(link: Link) async -> WordIndexingStatus {
        NSLog("index link: \(link)")
        var wordsArray = words(fromText: link.text)
        let countLimit = 40
        if wordsArray.count > countLimit {
            wordsArray.removeLast(wordsArray.count - countLimit)
        }
        if wordsArray.count == 0 {
            return .complete
        }
        let counts = wordsArray.reduce(into: [:]) { counts, word in counts[word.lowercased(), default: 0] += 1 }
        NSLog("indexing, wordsArray: \(wordsArray)")
        let text = contextStringFrom(array: wordsArray, atIndex: 0)
        let crawler = await Crawler.shared()
        for i in (0..<wordsArray.count) {
            let dbClosed = await database.closed()
            if !crawler.canRun || dbClosed {
                return .ended
            }
            do {
                let wordText = wordsArray[i].lowercased()
                if wordText.count > 2 {
                    let key = prefix + wordText.lowercased() + "-" + link.url
                    let word = WordLink(word: wordText, url: link.url, text: text, wordCount: counts[wordText] ?? 0) //Word(links: [WordLink(urlHash: link.hash, word: wordText, text: text, wordCount: counts[wordText] ?? 0)])
                    /*if var dbWord: Word = await database.valueForKey(key) {
                        word.merge(with: dbWord)
                        //WordLink.merge(wordLinks: &dbWord.links, withWordLinks: word.links)
                        try await database.setValue(dbWord, forKey: key)
                    } else {*/
                    try await database.setValue(word, forKey: key)
                    //}
                }
            } catch {
                NSLog("Word index:link database.setValue failed.")
                try? await Task.sleep(seconds: 1.0)
                return .failed
            }
        }
        return .complete
    }
    
    // MARK: - Search
    
    public static func wordLinks(
        withSearchText searchText: String,
        count: Int
    ) async -> [WordLink] {
        var resultSet = Set<WordLink>()
        let searchWords = WordLink.words(fromText: searchText, lowerCase: true)
        for searchWord in searchWords {
            if searchWords.count > 0 && searchWord.count <= 2 {
                continue
            }
            await database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: WordLink.prefix + searchWord) { (key, wordLink: WordLink, stop) in
                resultSet.insert(wordLink)
            }
        }
        var result = Array(resultSet)
        result = await result.asyncFilter { wordLink in
            if let site: Site = await database.valueForKey(Site.prefix + wordLink.url.onionID) {
                if site.blocked ?? false {
                    return false
                }
            } else {
                NSLog("Couldn't get site from wordLink: \(wordLink)")
                return false
            }
            return true
        }
        result = result.sorted { $0.score > $1.score }
        if result.count > count {
            result.removeLast(result.count - count)
        }
        return result
    }
    
    // MARK: - Delegates

    public func hash(into hasher: inout Hasher) {
        hasher.combine(word + "-" + url)
    }
    
    // MARK: - Helpers
    
    static func words(fromText text: String, lowerCase: Bool = false) -> [String] {
        var result = [String]()
        let whiteCharacters = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\n_()[]-/:{}-+=*&^%$#@!~`?'\";,.<>\\|"))
        let words = text.components(separatedBy: whiteCharacters)
        let commonWords: Set = [
            "and",
            "the",
            "from",
            "for",
            "not",
            "with",
            "but",
            "any",
            "its",
            "can"
        ]
        for word in words {
            if word.count > 0 {
                let finalWords = word.camelCaseWords
                for finalWord in finalWords {
                    if finalWord.count < 16 {
                        let lowerCaseWord = finalWord.lowercased()
                        if commonWords.contains(lowerCaseWord) {
                            continue
                        }
                        if lowerCase {
                            result.append(lowerCaseWord)
                        } else {
                            result.append(finalWord)
                        }
                    }
                }
            }
        }
        return result
    }
    
    static func contextStringFrom(array: [String], atIndex: Int) -> String {
        let wordsCount = 20
        let halfOfCount = wordsCount / 2
        let startIndex = atIndex - halfOfCount < 0 ? 0 : atIndex - halfOfCount
        let endIndex = startIndex + wordsCount >= array.count ? array.count - 1 : startIndex + wordsCount
        return String.from(array: array, startIndex: startIndex, endIdnex: endIndex)
    }
}
