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
    
    static var numberOfProcessedSites = 0
    
    public var url: String
    var processed: Bool = false
    public var numberOfVisits = 0
    public var lastVisitTime = 0 // # of seconds since reference date.
    public var numberOfReports = 0
    public var blocked: Bool?
    
    public enum CodingKeys: String, CodingKey {
        case url
        case processed
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
        await database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Site.prefix) { (Key, site: Site, stop) in
            //NSLog("nextLinkToProcess, Key: \(Key)")
            if !site.processed {
                //NSLog("!site.processed site: \(site)")
                stop.pointee = true
                result = site
            } else {
                //NSLog("nextLinkToProcess else, Key: \(Key)")
            }
        }
        return result
    }
    
    public static func crawlNext() async {
        //NSLog("Site.crawlNext")
        if var nextSite = await nextSiteToProcess(),
           let link: Link = await database.value(forKey: Link.prefix + nextSite.url) {
            NSLog("Site.crawlNext nextSite: \(link.url.onionID)")
            do {
                try await Link.process(link: link)
                await nextSite.updateSiteProcessedAndSave()
            } catch {
                NSLog("Site crawlNext Link.process error: \(error)")
                switch error {
                case LinkProcessError.notAllowed:
                    await nextSite.updateSiteProcessedAndSave()
                default:
                    break
                }
            }
        } else {
            NSLog("can't find any site to process")
            try? await Link.crawlNext()
        }
    }
    
    mutating func updateSiteProcessedAndSave() async {
        //NSLog("updateSiteProcessedAndSave")
        processed = true
        await save()
        Site.numberOfProcessedSites += 1
        NSLog("Processed site #\(Site.numberOfProcessedSites)")
    }
    
    // MARK: - Saving
    
    public mutating func save() async {
        do {
            try await database.setValue(self, forKey: key)
        } catch {
            NSLog("Link save failed.")
            try? await Task.sleep(seconds: 1.0)
        }
    }
    
}
