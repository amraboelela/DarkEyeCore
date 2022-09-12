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

    public var canBeBlocked: Bool {
        let cannotBeBlockedSites: Set = [
            "5wvugn3zqfbianszhldcqz2u7ulj3xex6i3ha3c5znpgdcnqzn24nnid",
            "zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad"
        ]
        return !cannotBeBlockedSites.contains(self.onionID)
    }
    
    public var allowed: Bool {
        if onionID.count < 50 {
            return false
        }
        let forbiddenIDs: Set = [
            "2a2a2abbjsjcjwfuozip6idfxsxyowoi3ajqyehqzfqyxezhacur7oyd",
            "222222222xn2ozdb2mjnkjrvcopf5thb6la6yj24jvyjqrbohx5kccid",
            "kxmrdbwcqbgyokjbiv7droplwhxvli3s7yv5xddxgrtajdpdebgzzzqd",
            "drugsednqhasbyoyg2oekzbnllbujro54zrogqbf3p6e7qflxti5eeqd",
            "bmj5nf63plhudrvp7lxjaz7fktxvm3heffh364okvfsd3hjx24aalwqd",
            "2cardsowr7u7uvpyrnc5lxuclhb4noj6q2cqf2so7ezg2zufntkjefad",
            "bithacklfxiag2kysa7inceduv3eijqmcbms26w25cmgwuwga4ucbaqd",
            "darkcctef2gtydfcgslrwj6vmu3ktse6pu5el7btczbfhsgiqtsrsoqd",
            "bd7uqvma4x3qfzwpa6pkrgdvtthd5hd2j4qdcvhb2fmpwuen5tdnrmqd",
            "56dlutemceny6ncaxolpn6lety2cqfz5fd64nx4ohevj4a7ricixwzad",
            "deep2v63hwfsupagnmzxyal6jxhtcxdennvcsekkji7qqic4jmjcj3yd",
            "moneye5g34sxtlo3jd2aft6hdphk2dtgvkwnk5taabfrqu75tutmynad",
            "buyreal2xipzjhjfhyztle35dknfexgqrpq4dmzvkc575kzi3vr6bmid",
            "dickvoz3shmr7f4ose43lwrkgljcrvdxy25f4eclk7wl3nls5p5i4nyd",
            "7afbko7mx7o654pbwbwydsiaukzp6wodzb54nf6tkz2h3nmnfa3bszid",
            "hssza6r6fbui4x452ayv3dkeynvjlkzllezxf3aizxppmcfmz2mg7uad",
            "524nypostlyxmdxhplizz3br2jfyjmnf27opin4axhpcemrxzfush2qd",
            "n3irlpzwkcmfochhuswpcrg35z7bzqtaoffqecomrx57n3rd5jc72byd",
            "bobby64o755x3gsuznts6hf6agxqjcz5bop6hs7ejorekbm7omes34ad",
            "courier2w2hawxspntosy3wolvc7g7tcrwhitiu4irrupnpqub2bqxid",
            "deepmej5tgxnpsmdgtvfghdg4dc2jwsddao473qtjmnbvs47dhxn3pid",
            "bananaen6hcopc4iwdt7xbnfjtxszgoe6a5pobfrbfmbol5ihweoxiid",
            "fc3ryhftqfgwyroq7pt63f7jif4jknfrmd3pbdwm4sz3myelf4wfz7qd",
            "fxrx6qvrri4ldt7dhytdvkuakai75bpdlxlmner6zrlkq34rpcqpyqyd",
            "csalryx3xenotyljyttsju6jfthrjyt6ijwd3zzykhkpyfoeao2nxaqd",
            "gocdtu23yutzszejz4ar5axa7nmmz2oxs2ce3ivrld63axbcq5lsvdqd"
        ]
        return !forbiddenIDs.contains(onionID) && blocked != true
    }
    // MARK: - Crawling
    
    static func nextSiteToProcess() async -> Site? {
        //NSLog("nextLinkToProcess")
        var result: Site? = nil
        await database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Site.prefix) { (Key, site: Site, stop) in
            //NSLog("nextLinkToProcess, Key: \(Key)")
            if !site.processed && site.allowed {
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
        if var nextSite = await nextSiteToProcess() {
            do {
                if let link: Link = await database.value(forKey: Link.prefix + nextSite.url) {
                    try await Link.process(link: link)
                }
                await nextSite.updateSiteProcessedAndSave()
            }
            catch {
                switch error {
                case LinkProcessError.notAllowed:
                    if nextSite.canBeBlocked {
                        nextSite.blocked = true
                    }
                    await nextSite.updateSiteProcessedAndSave()
                default:
                    NSLog("Site crawlNext error: \(error)")
                }
            }
        } else {
            do {
                NSLog("can't find any site to process")
                try await Link.crawlNext()
            } catch {
                NSLog("Link.crawlNext() error: \(error)")
            }
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
            NSLog("Site, new site: \(self.onionID)")
            try await database.setValue(self, forKey: key)
        } catch {
            NSLog("Link save failed.")
            try? await Task.sleep(seconds: 1.0)
        }
    }
    
}
