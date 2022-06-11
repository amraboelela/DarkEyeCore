//
//  Link.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/8/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation
import SwiftLevelDB

public struct Link: Codable {
    public static let prefix = "link-"
    public static var processTimeThreshold = 1 // any link with last process time smaller, need to be processed
    
    public var url: String
    public var title: String?
    public var lastProcessTime: Int = 0 // # of seconds since reference date.
    public var numberOfVisits: Int = 0
    public var lastVisitTime: Int = 0 // # of seconds since reference date.
    
    // MARK: - Accessors
    
    static var firstKey: String? {
        var result : String?
        database.enumerateKeys(backward: false, startingAtKey: nil, andPrefix: prefix) { key, stop in
            result = key
            stop.pointee = true
        }
        return result
    }

    public var key: String {
        return Link.prefix + url
    }

    // MARK: - Factory methods
    
    public static func with(url: String) -> Link {
        return Link(url: url)
    }

    public static func from(key: String) -> Link {
        return Link(url: url(fromKey: key))
    }

    // MARK: - Reading
    
    public static func links(
        withSearchText searchText: String,
        count: Int
    ) -> [Link] {
        var result = [Link]()
        let searchWords = Word.words(fromText: searchText)
        if let firstWord = searchWords.first {
            var wordLinks = [String]()
            database.enumerateKeysAndValues(backward: true, startingAtKey: nil, andPrefix: Word.prefix + firstWord) { (key, word: Word, stop) in
                wordLinks.append(contentsOf: word.links.map { $0.url })
            }
            for wordLink in wordLinks {
                var foundTheSearch = true
                if let link: Link = database[prefix + wordLink] {
                    /*for i in 1..<searchWords.count {
                        let searchWord = searchWords[i]
                        if link.title?.lowercased().range(of: searchWord) == nil {
                            foundTheSearch = false
                            break
                        }
                    }*/
                    if foundTheSearch {
                        result.append(link)
                    }
                }
            }
            result = result.sorted { $0.numberOfVisits > $1.numberOfVisits }
            if result.count > count {
                result.removeLast(result.count - count)
            }
        }
        return result
    }
    
    // MARK: - Saving
    
    public func save() -> Bool {
        var newLink = false
        if let _: Link = database[key] {
        } else {
            newLink = true
            database[key] = self
        }
        return newLink
    }
    
    // MARK: - Processing
    
    public mutating func process() {
        lastProcessTime = Date.secondsSinceReferenceDate
        _ = save()
    }
    
    // MARK: - Helpers
    
    public static func url(fromKey key: String) -> String {
        let arr = key.components(separatedBy: "-")
        var result = ""
        if arr.count > 1 {
            result = arr[1]
        }
        return result
    }
    
}
