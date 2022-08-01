//
//  Word.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/10/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation

public enum WordIndexingStatus {
    case done     // done with next word
    case complete // finished all the words up to 500 word
    case ended    // ended as it can't run
}

public struct Word: Codable {
    public static let prefix = "word-"

    public var links: [WordLink]
    
    // MARK: - Indexing
    
    public static func indexNextWord(link: Link) -> WordIndexingStatus {
        var wordsArray = words(fromText: link.text)
        let countLimit = 700
        if wordsArray.count > countLimit {
            wordsArray.removeLast(wordsArray.count - countLimit)
        }
        let uniqueArray = Array(Set(wordsArray))
        let filteredArray = uniqueArray.filter { word in
            word.count > 2 && word.prefix(1).rangeOfCharacter(from: CharacterSet.decimalDigits) == nil
        }
        if link.lastWordIndex < filteredArray.count - 1 {
            let wordIndex = link.lastWordIndex + 1
            let sortedArray = filteredArray.sorted { $0.lowercased() < $1.lowercased() }
            let word = sortedArray[wordIndex]
            let counts = wordsArray.reduce(into: [:]) { counts, word in counts[word.lowercased(), default: 0] += 1 }
            NSLog("indexing, wordIndex: \(wordIndex), word: \(word.lowercased()), wordCount: \(wordsArray.count)")
            for i in (0..<wordsArray.count) {
                if !crawler.canRun || database.closed() {
                    return .ended
                }
                if word != wordsArray[i] {
                    continue
                }
                let wordText = wordsArray[i].lowercased()
                let text = contextStringFrom(array: wordsArray, atIndex: i)
                //print("wordText: \(wordText)")
                if crawler.canRun {
                    let key = prefix + wordText.lowercased()
                    //NSLog("index link key: \(key)")
                    let word = Word(links: [WordLink(urlHash: link.hash, text: text, wordCount: counts[wordText.lowercased()] ?? 0)])
                    if var dbWord: Word = database[key] {
                        WordLink.merge(wordLinks: &dbWord.links, withWordLinks: word.links)
                        database[key] = dbWord
                        return .done
                    } else {
                        database[key] = word
                        return .done
                    }
                } else {
                    return .ended
                }
            }
            if wordIndex >= filteredArray.count - 1 {
                return .complete
            } else {
                return .done
            }
        } else {
            NSLog("link.lastWordIndex > filteredArray.count - 1, link.lastWordIndex: \(link.lastWordIndex), filteredArray.count: \(filteredArray.count)")
            return .complete
        }
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
        let wordsCount = 30
        let halfOfCount = wordsCount / 2
        let startIndex = atIndex - halfOfCount < 0 ? 0 : atIndex - halfOfCount
        let endIndex = startIndex + wordsCount >= array.count ? array.count - 1 : startIndex + wordsCount
        return String.from(array: array, startIndex: startIndex, endIdnex: endIndex)
    }
}
