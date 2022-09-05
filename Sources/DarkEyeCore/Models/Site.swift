//
//  Site.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 9/4/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation
import SwiftLevelDB
import Fuzi
import SwiftEncrypt

public struct Site: Codable, Sendable {
    public static let prefix = "site-"
    public static var workingDirectory = ""
    
    //public var onionID: String
    public var url: String
    var indexed: Bool = false
    public var numberOfVisits = 0
    public var lastVisitTime = 0 // # of seconds since reference date.
    public var numberOfReports = 0
    public var blocked: Bool?
    
    public enum CodingKeys: String, CodingKey {
        //case onionID
        case url
        case indexed
        case numberOfVisits
        case lastVisitTime
        case numberOfReports
        case blocked
    }
    
    // MARK: - Accessors
    
    static func firstKey() async -> String? {
        var result : String?
        await database.enumerateKeys(backward: false, startingAtKey: nil, andPrefix: prefix) { key, stop in
            result = key
            stop.pointee = true
        }
        return result
    }

    var onionID: String {
        return url.onionID
    }
    
    var key: String {
        return Site.prefix + onionID
    }

    // MARK: - Crawling
    
    static func nextSiteToProcess() async -> Site? {
        //NSLog("nextLinkToProcess")
        var result: Site? = nil
        //let processTimeThreshold = await Global.global().processTimeThreshold
        await database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Site.prefix) { (Key, site: Site, stop) in
            //NSLog("nextLinkToProcess, Key: \(Key)")
            if !site.indexed {
                stop.pointee = true
                result = site
            } else {
                //NSLog("nextLinkToProcess else, Key: \(Key)")
            }
        }
        return result
    }
    
    // MARK: - Saving
    
    public mutating func save() async {
        do {
            /*if let _: Link = await database.valueForKey(key) {
            } else {
                //let hashLink = HashLink(url: url)
                //try await database.setValue(hashLink, forKey: HashLink.prefix + hash)
            }*/
            try await database.setValue(self, forKey: key)
        } catch {
            NSLog("Link save failed. Exiting")
            exit(1)
        }
    }
    
}
