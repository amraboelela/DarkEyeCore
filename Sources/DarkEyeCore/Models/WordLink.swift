//
//  WordLink.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/14/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation
import SwiftEncrypt

@available(macOS 10.15.0, *)
public struct WordLink: Codable {
    public var urlHash: String
    public var word: String
    var otherWords: Set<String>?
    public var text: String
    public var wordCount: Int
    public var numberOfVisits: Int = 0
    public var lastVisitTime: Int = 0
    
    public enum CodingKeys: String, CodingKey {
        case urlHash
        case word
        case text
        case wordCount
        case numberOfVisits
        case lastVisitTime
    }
    
    // MARK: - Accessors
    
    public func hashLink() async -> HashLink? {
        if let result: HashLink = await database.valueForKey(HashLink.prefix + urlHash) { //[HashLink.prefix + urlHash] {
            return result
        }
        return nil
    }
    
    var score: Int {
        return numberOfVisits * 1000 + wordCount + lastVisitTime
    }
    
    // MARK: - Search
    
    public static func wordLinks(
        withSearchText searchText: String,
        count: Int
    ) async -> [WordLink] {
        var result = [WordLink]()
        let searchWords = Word.words(fromText: searchText, lowerCase: true)
        for searchWord in searchWords {
            if searchWords.count > 0 && searchWord.count <= 2 {
                continue
            }
            await database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Word.prefix + searchWord) { (key, word: Word, stop) in
                WordLink.merge(wordLinks: &result, withWordLinks: word.links)
            }
            
            result = await result.asyncFilter { wordLink in
                if let link = await wordLink.hashLink()?.link() {
                    if link.blocked == true {
                        return false
                    }
                } else {
                    NSLog("Couldn't get wordLink for urlHash: \(wordLink.urlHash)")
                    return false
                }
                return true
            }
        }
        result = result.sorted { $0.score > $1.score }
        if result.count > count {
            result.removeLast(result.count - count)
        }
        return result
    }
    
    // MARK: - Helpers
    
    static func merge(wordLinks: inout [WordLink], withWordLinks: [WordLink]) {
        //print("merge wordLinks.count: \(wordLinks.count) withWordLinks.count: \(withWordLinks.count)")
        for withWordLink in withWordLinks {
            if let index = wordLinks.firstIndex(where: { $0.urlHash == withWordLink.urlHash }) {
                var wordLink = wordLinks[index]
                wordLink.mergeWith(wordLink: withWordLink)
                wordLinks[index] = wordLink
            } else {
                wordLinks.append(withWordLink)
            }
        }
    }
    
    mutating func mergeWith(wordLink: WordLink) {
        if urlHash == wordLink.urlHash &&
            word != wordLink.word &&
            otherWords?.contains(wordLink.word) != true {
            if otherWords == nil {
                otherWords = Set<String>()
            }
            otherWords?.insert(wordLink.word)
            if wordLink.text != text {
                text += "..." + wordLink.text
            }
            wordCount += wordLink.wordCount
        }
    }
}
