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
    case notFound
    case ended    // ended as it can't run
}

public struct Word: Codable {
    public static let prefix = "word-"

    public var links: [WordLink]
    
    // MARK: - Indexing
    
    public static func indexNextWord(link: Link) -> WordIndexingStatus {
        var wordsArray = words(fromText: link.text)
        let countLimit = 1000
        if wordsArray.count > countLimit {
            wordsArray.removeLast(wordsArray.count - countLimit)
        }
        let uniqueArray = Array(Set(wordsArray))
        let filteredArray = uniqueArray.filter { word in
            word.count > 2 && word.prefix(1).rangeOfCharacter(from: CharacterSet.decimalDigits) == nil
        }
        let whiteCharacters = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "_"))
        let cleanArray = filteredArray.map { word in
            return word.trimmingCharacters(in: whiteCharacters)
        }
        if link.lastWordIndex < cleanArray.count - 1 {
            let wordIndex = link.lastWordIndex + 1
            let sortedArray = cleanArray.sorted { $0.lowercased() < $1.lowercased() }
            let word = sortedArray[wordIndex]
            let counts = wordsArray.reduce(into: [:]) { counts, word in counts[word.lowercased(), default: 0] += 1 }
            NSLog("indexing wordsArray.count: \(wordsArray.count), wordIndex: \(wordIndex), word: \(word)")
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
            if wordIndex == wordsArray.count - 1 {
                return .complete
            } else {
                return .done
            }
        } else {
            NSLog("link.lastWordIndex < filteredArray.count - 1, link.lastWordIndex: \(link.lastWordIndex), filteredArray.count: \(filteredArray.count)")
            return .complete
        }
        return .notFound
    }
    
    // MARK: - Helpers
    
    static func words(fromText text: String, lowerCase: Bool = false) -> [String] {
        var result = [String]()
        let words = text.components(separatedBy: String.characters.inverted)
        for word in words {
            if word.count > 0 {
                let finalWords = word.camelCaseWords
                for finalWord in finalWords {
                    if finalWord.count < 16 {
                        if lowerCase {
                            result.append(finalWord.lowercased())
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
        let startIndex = atIndex - 10 < 0 ? 0 : atIndex - 10
        let endIndex = startIndex + 20 >= array.count ? array.count - 1 : startIndex + 20
        return String.from(array: array, startIndex: startIndex, endIdnex: endIndex)
    }
}
