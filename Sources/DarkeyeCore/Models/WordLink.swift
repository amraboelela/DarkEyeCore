//
//  WordLink.swift
//  DarkeyeCore
//
//  Created by Amr Aboelela on 6/10/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation

public enum WordStatus {
    case complete // finished all the words up to 500 word
    case ended    // ended as it can't run
    case notAllowed
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
    
    func score() async -> Int {
        var numberOfLinks = 1
        if let link = await link() {
            numberOfLinks = link.numberOfLinks
        }
        return numberOfLinks * 1000 + numberOfVisits * 500 + wordCount * 100 + lastVisitTime
    }
    
    func link() async -> Link? {
        if let link: Link = await database.value(forKey: Link.prefix + url) {
            return link
        }
        return nil
    }
    
    // MARK: - Indexing
    
    public static func index(link: Link) async -> WordStatus {
        //NSLog("index link: \(link)")
        var wordsArray = Word.words(fromText: await link.text())
        let countLimit = 40
        if wordsArray.count > countLimit {
            wordsArray.removeLast(wordsArray.count - countLimit)
        }
        if wordsArray.count == 0 {
            NSLog("indexing, wordsArray.count == 0")
            return .complete
        }
        let counts = wordsArray.reduce(into: [:]) { counts, word in counts[word.lowercased(), default: 0] += 1 }
        NSLog("indexing, wordsArray: \(wordsArray)")
        let text = Word.contextStringFrom(array: wordsArray, atIndex: 0)
        let crawler = await Crawler.shared()
        wordsArray = wordsArray.map { $0.lowercased() }
        if !Word.allowed(wordsArray: wordsArray) {
            return .notAllowed
        }
        for word in wordsArray {
            let dbClosed = await database.closed()
            if !crawler.canRun || dbClosed {
                return .ended
            }
            do {
                if word.count > 2 {
                    let key = prefix + word + "-" + link.url
                    let wordLink = WordLink(word: word, url: link.url, text: text, wordCount: counts[word] ?? 0)
                    try await database.setValue(wordLink, forKey: key)
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
        let searchWords = Word.words(fromText: searchText, lowerCase: true)
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
            if let site: Site = await database.value(forKey: Site.prefix + wordLink.url.onionID) {
                if site.blocked == true {
                    return false
                }
            } else {
                NSLog("Couldn't get site from wordLink: \(wordLink)")
                return false
            }
            return true
        }
        await result.insertionSort { await $0.score() > $1.score() }
        if result.count > count {
            result.removeLast(result.count - count)
        }
        return result
    }
    
    // MARK: - Delegates

    public func hash(into hasher: inout Hasher) {
        hasher.combine(word + "-" + url)
    }
}
