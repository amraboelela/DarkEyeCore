//
//  Link.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/8/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation
import SwiftLevelDB
import Fuzi
import SwiftEncrypt

public struct Link: Codable, Sendable {
    public static let prefix = "link-"
    
    static var numberOfProcessedLinks = 0
    static var numberOfIndexedLinks = 0
    
    public var url: String
    public var lastProcessTime = 0 // # of seconds since reference date.
    public var failedToLoad = false
    //public var lastWordIndex = -1 // last indexed word index
    public var numberOfVisits = 0
    public var lastVisitTime = 0 // # of seconds since reference date.
    //public var numberOfReports = 0
    //public var blocked: Bool?
    
    public enum CodingKeys: String, CodingKey {
        case url
        case lastProcessTime
        case failedToLoad
        //case lastWordIndex
        case numberOfVisits
        case lastVisitTime
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

    var key: String {
        return Link.prefix + url
    }

    var base: String {
        if let onionRange = url.range(of: ".onion") {
            return String(url.prefix(upTo: onionRange.upperBound))
        }
        return ""
    }
    
    public var hash: String {
        return url.hashBase32(numberOfDigits: 12)
    }
    
    static var cachedHtml = [String: String]()
    
    public var html: String? {
        if let cachedHtml = Link.cachedHtml[self.url] {
            return cachedHtml
        }
#if os(Linux)
        let thresholdDays = 100
#else
        let thresholdDays = 1000
#endif
        let fileURL = Global.cacheURL.appendingPathComponent(hash + ".html")
        //NSLog("cachedFile fileURL: \(fileURL)")
        var result: String?
        result = try? String(contentsOf: fileURL, encoding: .utf8)
        if let attr = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            if let fileSize = attr[FileAttributeKey.size] as? NSNumber, fileSize.intValue == 0 {
                //NSLog("cachedFile, fileSize == 0, url: \(url)")
                result = nil
            }
            if let fileDate = attr[FileAttributeKey.modificationDate] as? NSDate {
                let cacheThreashold = Date.days(numberOfDays: thresholdDays)
                let secondsDiff = Date().timeIntervalSinceReferenceDate - fileDate.timeIntervalSinceReferenceDate
                if secondsDiff > cacheThreashold {
                    NSLog("secondsDiff > cacheThreashold. cacheThreashold: \(cacheThreashold)")
                    result = nil
                }
            }
        }
        if result == nil {
#if os(Linux)
            do {
                //let cacheFileURL = Link.cacheURL.appendingPathComponent(hash + ".html")
                //let tempFileURL = Link.cacheURL.appendingPathComponent(hash + "-temp.html")
                if let shellResult = try shell("torsocks", "wget", "-O", fileURL.path, url) {
                    NSLog("torsocks shellResult: \(shellResult.prefix(200))")
                    //NSLog("torsocks shellResult: \(shellResult)")
                }
                if let fileContent = try? String(contentsOf: fileURL, encoding: .utf8), !fileContent.isVacant {
                    //if let fileContent = try shell("cat", cacheFileURL.path) {
                    result = fileContent
                } else {
                    NSLog("error getting fileContent, fileURL: \(fileURL.path)")
                }
                //_ = try shell("rm", tempFileURL.path)
            } catch {
                NSLog("html, error: \(error)")
            }
#endif
        }
        if result == nil {
            NSLog("html returns nil")
        }
        Link.cachedHtml[self.url] = result
        return result
    }
    
    public var title: String {
        var result = ""
        if let html = html, let doc = try? HTMLDocument(string: html) {
            result += doc.title ?? ""
        }
        return result.replacingOccurrences(
            of: "[ \n]+",
            with: " ",
            options: .regularExpression).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    public var text: String {
        var result = ""
        if let html = html, let doc = try? HTMLDocument(string: html) {
            result += doc.title ?? ""
            if let textNodes = doc.body?.childNodes(ofTypes: [.Element]) {
                for textNode in textNodes {
                    if textNode.toElement()?.tag != "script" {
                        result += " " + textNode.stringValue + " "
                    }
                }
            }
        }
        return result.replacingOccurrences(
            of: "[ \n]+",
            with: " ",
            options: .regularExpression).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    // Returns raw urls and refined urls
    public var urls: [(String, String)] {
        var result = [(String,String)]()
        if let html = html, let doc = try? HTMLDocument(string: html) {
            if let nodes = doc.body?.childNodes(ofTypes: [.Element]) {
                for node in nodes {
                    if let elementNode = node.toElement() {
                        let anchorNodes = anchorNodesFrom(node: elementNode)
                        result.append(contentsOf: anchorNodes.compactMap { anchor in
                            if let href = anchor["href"], href.range(of: "#") == nil {
                                if !Link.allowed(url: href) {
                                    Link.remove(url: href)
                                    return nil
                                }
                                var refinedHref = href
                                if refinedHref.last == "/" {
                                    refinedHref = String(refinedHref.dropLast())
                                }
                                if refinedHref.range(of: "//www.")?.lowerBound == refinedHref.startIndex {
                                    refinedHref = refinedHref.replacingOccurrences(of: "//www", with: "http://www")
                                }
                                if refinedHref.range(of: "www.")?.lowerBound == refinedHref.startIndex {
                                    refinedHref = refinedHref.replacingOccurrences(of: "www", with: "http://www")
                                }
                                if refinedHref.first == "/" {
                                    return (href.htmlEncoded, base + refinedHref)
                                } else if refinedHref.range(of: ".onion") != nil {
                                    return (href.htmlEncoded, refinedHref)
                                }
                            }
                            return nil
                        })
                    }
                }
            }
        }
        return result
    }
    
    // MARK: - Accessor functions
    
    func site() async -> Site? {
        if let site: Site = await database.valueForKey(Site.prefix + url.onionID) {
            return site
        }
        return nil
    }
    
    func blocked() async -> Bool {
        return await site()?.blocked ?? false
    }
    
    // MARK: - Factory methods
    
    static func with(url: String) -> Link {
        return Link(url: url)
    }

    static func from(key: String) -> Link {
        return Link(url: url(fromKey: key))
    }

    // MARK: - Crawling
    
    static func nextLinkToProcess() async -> Link? {
        //NSLog("nextLinkToProcess")
        var result: Link? = nil
        let processTimeThreshold = await Global.global().processTimeThreshold
        await database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Link.prefix) { (Key, link: Link, stop) in
            if link.lastProcessTime < processTimeThreshold {
                stop.pointee = true
                result = link
            } else {
                //NSLog("nextLinkToProcess else, Key: \(Key)")
            }
        }
        return result
    }
    
    public static func crawlNext() async {
        //NSLog("crawlNext")
        if let nextLink = await nextLinkToProcess() {
            //print("crawlNext nextLink: \(nextLink.url)")
            await Link.process(link: nextLink)
        } else {
            //await updateCurrentWordIndex()
            if let nextLink = await nextLinkToProcess() {
                //NSLog("crawlNext nextLink: \(nextLink.url)")
                await Link.process(link: nextLink)
            } else {
                NSLog("can't find any link to process")
            }
        }
    }
    
    static func process(link: Link) async {
        NSLog("processing link: \(link.url)")
        let crawler = await Crawler.shared()
        let dbClosed = await database.closed()
        if !crawler.canRun || dbClosed {
            return
        }
        var myLink = link
        if await myLink.blocked() == true || myLink.html == nil {
            Link.remove(url: myLink.url)
            await myLink.updateLinkProcessedAndSave()
        } else if myLink.html == nil {
            await myLink.updateLinkProcessedAndSave()
        } else {
            await myLink.saveChildren()
            switch await Word.index(link: myLink) {
            //case .done:
            //    await myLink.updateLinkIndexedAndSave()
            case .complete:
                await myLink.updateLinkProcessedAndSave()
            case .ended:
                NSLog("indexNextWord returned .ended")
            case .failed:
                NSLog("indexNextWord returned .failed")
            }
        }
    }
    
    mutating func updateLinkIndexedAndSave() async {
        //lastWordIndex += 1
        await save()
        Link.numberOfIndexedLinks += 1
        /*if Link.numberOfIndexedLinks > 1000 {
            Link.numberOfIndexedLinks = 0
            //await Link.updateCurrentWordIndex()
        }*/
        NSLog("indexed link #\(Link.numberOfIndexedLinks)")
    }
    
    mutating func updateLinkProcessedAndSave() async {
        NSLog("updateLinkProcessedAndSave")
        //lastWordIndex = -1
        lastProcessTime = Date.secondsSinceReferenceDate
        await save()
        Link.numberOfProcessedLinks += 1
        NSLog("processed link #\(Link.numberOfProcessedLinks)")
    }
    
    public mutating func saveChildrenIfNeeded() async {
        //print("saveChildrenIfNeeded")
        if await lastProcessTime < Global.global().processTimeThreshold {
            await saveChildren()
        }
    }
    
    mutating func saveChildren() async {
        NSLog("saveChildren")
        for (_, childURL) in urls {
            if let _: Link = await database.valueForKey(Link.prefix + childURL) {
            } else {
                var link = Link(url: childURL)
                await link.save()
            }
        }
    }
    
    // MARK: - Saving
    
    public mutating func save() async {
        do {
            if let _: Link = await database.valueForKey(key) {
            } else {
                let hashLink = HashLink(url: url)
                try await database.setValue(hashLink, forKey: HashLink.prefix + hash)
                let site = Site(url: url)
                try await database.setValue(site, forKey: Site.prefix + url.onionID)
            }
            try await database.setValue(self, forKey: key)
        } catch {
            NSLog("Link save failed.")
            try? await Task.sleep(seconds: 1.0)
        }
    }
    
    // MARK: - Helpers
    
    static func allowed(url: String) -> Bool {
        if url.range(of: ":") != nil &&
            url.range(of: "http") == nil {
            return false
        }
        let forbiddenExtensions = [
            ".png",
            ".jpg",
            ".mp4",
            ".zip",
            ".gif",
            ".epub",
            ".nib",
            ".nb0",
            ".php",
            ".pdf",
            ".asc",
            ".webm",
            "?menu=1"
        ]
        for anExtension in forbiddenExtensions {
            if url.suffix(anExtension.count).range(of: anExtension) != nil {
                return false
            }
        }
        let forbiddenTerms = [
            "beverages",
            "money-transfers",
            "music",
            ".media",
            "_media",
            ".php?",
            "2a2a2abbjsjcjwfuozip6idfxsxyowoi3ajqyehqzfqyxezhacur7oyd",
            "222222222xn2ozdb2mjnkjrvcopf5thb6la6yj24jvyjqrbohx5kccid"
        ]
        for term in forbiddenTerms {
            if url.range(of: term) != nil {
                return false
            }
        }
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ":._?/-="))
        if url.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return false
        }
        return true
    }
    
    static func url(fromKey key: String) -> String {
        let arr = key.components(separatedBy: "-")
        var result = ""
        if arr.count > 1 {
            result = arr[1]
        }
        return result
    }
    
    func anchorNodesFrom(node: Fuzi.XMLElement) -> [Fuzi.XMLElement] {
        var result = [Fuzi.XMLElement]()
        if node.toElement()?.tag == "a" {
            result.append(node)
        } else {
            for childNode in node.children {
                result.append(contentsOf: anchorNodesFrom(node: childNode))
            }
        }
        return result
    }
    
    static func remove(url: String) {
        let hash = url.hashBase32(numberOfDigits: 12)
        let filePath = Global.cacheURL.appendingPathComponent(hash + ".html").path
        try? FileManager.default.removeItem(atPath: filePath)
    }
    
}
