//
//  Word.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/10/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation

public struct Word: Codable {
    public static let prefix = "word-"

    public var links: [WordLink]
    
    // MARK: - Indexing
    
    public static func index(link: Link) -> Bool {
        //print("index link: \(link.url)")
        var processedKeys = Set<String>()
        var wordsArray = words(fromText: link.text)
        if wordsArray.count > 1000 {
            wordsArray.removeLast(wordsArray.count - 1000)
        }
        let counts = wordsArray.reduce(into: [:]) { counts, word in counts[word.lowercased(), default: 0] += 1 }
        NSLog("indexing wordsArray.count: \(wordsArray.count)")
        for i in (0..<wordsArray.count) {
            /*if !crawler.canRun || database.closed() {
                return false
            }*/
            let wordText = wordsArray[i].lowercased()
            if processedKeys.contains(wordText) {
                continue
            }
            processedKeys.insert(wordText)
            let text = contextStringFrom(array: wordsArray, atIndex: i)
            //print("wordText: \(wordText)")
            if wordText.count > 2 {
                /*DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.01) {
                    crawler.serialQueue.async {
                        if crawler.canRun {
                            let key = prefix + wordText.lowercased()
                            //NSLog("index link key: \(key)")
                            let word = Word(links: [WordLink(url: link.url, title: link.title, text: text, wordCount: counts[wordText.lowercased()] ?? 0)])
                            if var dbWord: Word = database[key] {
                                WordLink.merge(wordLinks: &dbWord.links, withWordLinks: word.links)
                                database[key] = dbWord
                            } else {
                                database[key] = word
                            }
                        }
                    }
                }*/
            }
        }
        return true
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
