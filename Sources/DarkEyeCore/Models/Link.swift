//
//  Link.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/8/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation
import SwiftLevelDB

public struct LinksContainer: Codable {
    public var links: [Link]
}

public struct Link: Codable {
    public static let prefix = "link-"
    public static var links = [Link]()
    
    public var url: String
    public var title: String?
    public var lastProcessTime: Int? // # of seconds since reference date.
    public var numberOfVisits: Int = 0
    public var lastVisitTime: Int? // # of seconds since reference date.
    
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
