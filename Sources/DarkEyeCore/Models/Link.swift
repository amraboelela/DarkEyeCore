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
        return Link.prefix + "-" + url
    }

    // MARK: - Reading data
    
    public static func with(url: String) -> Link {
        return Link(url: url)
    }

    public static func from(key: String) -> Link {
        return Link(url: url(fromKey: key))
    }

    
    public static func links(
        withSearchText searchText: String,
        time: Int? = nil,
        before: Bool = true,
        count: Int
    ) -> [Link] {
        var result = [Link]()
        let searchWords = Word.words(fromText: searchText)
        if let firstWord = searchWords.first {
            var wordPostKeys = [String]()
            database.enumerateKeysAndValues(backward: true, startingAtKey: nil, andPrefix: Word.prefix + firstWord) { (key, word: Word, stop) in
                if time == nil {
                    wordPostKeys.append(word.postKey)
                } else if let time = time {
                    if before {
                        if Word.time(fromKey: key) <= time {
                            wordPostKeys.append(word.postKey)
                        }
                    } else {
                        if Word.time(fromKey: key) >= time {
                            wordPostKeys.append(word.postKey)
                        }
                    }
                }
            }
            for wordPostKey in wordPostKeys {
                var foundTheSearch = true
                if let link: Link = database[wordPostKey] {
                    for i in 1..<searchWords.count {
                        let searchWord = searchWords[i]
                        if link.title?.lowercased().range(of: searchWord) == nil {
                            foundTheSearch = false
                            break
                        }
                    }
                    if foundTheSearch {
                        result.append(link)
                    }
                }
            }
            result = result.sorted { $0.numberOfVisits > $1.numberOfVisits }
            if result.count > count {
                result.removeLast(result.count - count)
            }
        } /*else {
            //logger.log("getPosts, searchText is empty")
            var startAtKey: String? = nil
            if let time = time {
                startAtKey = prefix + "\(time)"
            } else {
                database.enumerateKeysAndValues(backward: before, startingAtKey: startAtKey, andPrefix: prefix) { (key, post: Post, stop) in
                    if result.count < count {
                        result.append(post)
                    } else {
                        stop.pointee = true
                    }
                }
            }
            
        }*/
        return result
    }
    
    // MARK: - Saving data
    
    public static func save(links: [Link]) -> Int {
        var saveCount = 0
        for link in links {
            if self.save(link: link) {
                saveCount+=1;
            }
        }
        return saveCount
    }
    
    // MARK: - Public functions
    
    public static func key(ofLink link: Link) -> String {
        return prefix + "-" + link.url
    }
    
    public static func crawl() {
        
    }
    
    public static func save(link: Link) -> Bool {
        var newLink = false
        let url = link.url
        let key = prefix + "-" + url
        if let _: Link = database[key] {
        } else {
            newLink = true
            database[key] = link
        }
        return newLink
    }
    
    public static func url(fromKey key: String) -> String {
        let arr = key.components(separatedBy: "-")
        var result = ""
        if arr.count > 1 {
            result = arr[1]
        }
        return result
    }
    
    public static func links(forKeys keys: [String]) -> [Link] {
        var result = [Link]()
        for linkKey in keys {
            if let link: Link = database[linkKey] {
                result.append(link)
            }
        }
        return result
    }
    
}
