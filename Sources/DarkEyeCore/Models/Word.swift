//
//  Word.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/10/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation

public enum WordIndexingStatus {
    case done     // done with next word
    case complete // finished all the words up to 500 word
    case ended    // ended as it can't run
}

public struct Word: Codable, Sendable {
    public static let prefix = "word-"

    public var links: [WordLink]
    
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
                    let key = prefix + wordText.lowercased()
                    let word = Word(links: [WordLink(urlHash: link.hash, word: wordText, text: text, wordCount: counts[wordText] ?? 0)])
                    if var dbWord: Word = await database.valueForKey(key) {
                        WordLink.merge(wordLinks: &dbWord.links, withWordLinks: word.links)
                        try await database.setValue(dbWord, forKey: key)
                    } else {
                        try await database.setValue(word, forKey: key)
                    }
                }
            } catch {
                NSLog("Word index:link database.setValue failed. Exiting")
                exit(1)
            }
        }
        return .complete
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
