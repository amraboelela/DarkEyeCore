//
//  WordLink.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/14/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation
import SwiftEncrypt

public struct WordLink: Codable {
    public var urlHash: String
    public var text: String
    public var wordCount: Int
    public var numberOfVisits: Int = 0
    public var lastVisitTime: Int = 0
    
    // MARK: - Accessors
    
    public var hashLink: HashLink? {
        if let result: HashLink = database[HashLink.prefix + urlHash] {
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
    ) -> [WordLink] {
        var result = [WordLink]()
        let searchWords = Word.words(fromText: searchText, lowerCase: true)
        for searchWord in searchWords {
            database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Word.prefix + searchWord) { (key, word: Word, stop) in
                WordLink.merge(wordLinks: &result, withWordLinks: word.links)
            }
            result = result.filter { wordLink in
                if let link = wordLink.hashLink?.link {
                    if link.blocked == true {
                        return false
                    }
                } else {
                    NSLog("Couldn't get wordLink for urlHash: \(wordLink.urlHash)")
                    return false
                }
                return true
            }
            result = result.sorted { $0.score > $1.score }
            if result.count > count {
                result.removeLast(result.count - count)
            }
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
        text = wordLink.text
        wordCount = wordLink.wordCount
    }
}
