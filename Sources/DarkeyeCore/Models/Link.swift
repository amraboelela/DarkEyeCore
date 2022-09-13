//
//  Link.swift
//  DarkeyeCore
//
//  Created by Amr Aboelela on 6/8/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation
import SwiftLevelDB
import Fuzi
import SwiftEncrypt

enum LinkProcessError: Error {
    case cannotRun
    case notAllowed
    case failed
}

public struct Link: Codable, Equatable, Sendable {
    public static let prefix = "link-"
    
    static var numberOfProcessedLinks = 0
    
    public var url: String
    public var lastProcessTime = 0 // # of seconds since reference date.
    public var failedToLoad = false
    public var numberOfVisits = 0
    public var lastVisitTime = 0 // # of seconds since reference date.
    
    public enum CodingKeys: String, CodingKey {
        case url
        case lastProcessTime
        case failedToLoad
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
    
    public func html() async -> String? {
        //NSLog("getting html")
        if let cachedHtml = Link.cachedHtml[self.url] {
            return cachedHtml
        }
#if os(Linux)
        let thresholdDays = 100
#else
        let thresholdDays = 1000
#endif
        var needToRefresh = false
        let fileURL = Global.cacheURL.appendingPathComponent(hash + ".html")
        //NSLog("cachedFile fileURL: \(fileURL)")
        var result: String?
        result = try? String(contentsOf: fileURL, encoding: .utf8)
        if let attr = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
            let fileDate = attr[FileAttributeKey.modificationDate] as? NSDate {
            let cacheThreashold = Date.days(numberOfDays: thresholdDays)
            let secondsDiff = Date().timeIntervalSinceReferenceDate - fileDate.timeIntervalSinceReferenceDate
            if secondsDiff > cacheThreashold {
                NSLog("secondsDiff > cacheThreashold: \(cacheThreashold/(24*60*60)) days")
                needToRefresh = true
            }
        }
        if result == nil || needToRefresh {
#if os(Linux)
            do {
                NSLog("needToRefresh, calling torsocks")
                if let shellResult = try await shell(timeout: 5 * 60, "torsocks", "wget", "-O", fileURL.path, url) {
                    NSLog("torsocks shellResult: \(shellResult.prefix(200))")
                }
                if let fileContent = try? String(contentsOf: fileURL, encoding: .utf8), !fileContent.isVacant {
                    result = fileContent
                } else {
                    NSLog("error getting fileContent, fileURL: \(fileURL.path)")
                }
            } catch {
                NSLog("html, error: \(error)")
                if "\(error)".contains("Bad file descriptor") {
                    exit(1)
                }
            }
#endif
        }
        if result == nil {
            NSLog("html returns nil")
        }
        Link.cachedHtml[self.url] = result
        return result
    }
    
    public func title() async -> String {
        var result = ""
        if let html = await html(), let doc = try? HTMLDocument(string: html) {
            result += doc.title ?? ""
        }
        result = result.replacingOccurrences(
            of: "[ \n]+",
            with: " ",
            options: .regularExpression).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return String(result.prefix(100))
    }
    
    public func text() async -> String {
        var result = ""
        if let html = await html(), let doc = try? HTMLDocument(string: html) {
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
    public func urls() async -> [(String, String)] {
        var result = [(String,String)]()
        if let html = await html(), let doc = try? HTMLDocument(string: html) {
            if let nodes = doc.body?.childNodes(ofTypes: [.Element]) {
                for node in nodes {
                    if let elementNode = node.toElement() {
                        let anchorNodes = anchorNodesFrom(node: elementNode)
                        result.append(contentsOf: anchorNodes.compactMap { anchor in
                            if let href = anchor["href"], href.range(of: "#") == nil {
                                if !Link.allowed(url: href) {
                                    //Link.remove(url: href)
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
    
    public func site() async -> Site? {
        if let site: Site = await database.value(forKey: Site.prefix + url.onionID) {
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
        var availableLinks = [Link]()
        await database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Link.prefix) { (Key, link: Link, stop) in
            if link.lastProcessTime < processTimeThreshold {
                //stop.pointee = true
                //result = link
                availableLinks.append(link)
            } else {
                //NSLog("nextLinkToProcess else, Key: \(Key)")
            }
        }
        if availableLinks.count > 0 {
            let chosenLinkIndex = Int.random(in: 0..<availableLinks.count)
            result = availableLinks[chosenLinkIndex]
        }
        return result
    }
    
    public static func crawlNext() async throws {
        NSLog("Link.crawlNext")
        if let nextLink = await nextLinkToProcess() {
            //print("crawlNext nextLink: \(nextLink.url)")
            try await Link.process(link: nextLink)
        } else {
            NSLog("can't find any link to process")
        }
    }
    
    static func process(link: Link) async throws {
        NSLog("processing link: \(link.url)")
        var myLink = link
        //NSLog("process link, site: \(String(describing: await link.site()))")
        //NSLog("process link, blocked: \(await link.blocked())")
        if await link.blocked() || !allowed(url: link.url) {
            NSLog("link not allowed")
            await myLink.updateLinkProcessedAndSave()
            throw LinkProcessError.notAllowed
        }
        let crawler = await Crawler.shared()
        let dbClosed = await database.closed()
        if !crawler.canRun || dbClosed {
            throw LinkProcessError.cannotRun
        }
        if await link.html() == nil {
            //NSLog("myLink.html() == nil ")
            await myLink.updateLinkProcessedAndSave()
        } else {
            switch await WordLink.index(link: myLink) {
            case .complete:
                await myLink.saveChildren()
                await myLink.updateLinkProcessedAndSave()
            case .ended:
                NSLog("indexNextWord returned .ended")
                throw LinkProcessError.cannotRun
            case .notAllowed:
                NSLog("url not allowed")
                await myLink.updateLinkProcessedAndSave()
                throw LinkProcessError.notAllowed
            case .failed:
                NSLog("indexNextWord returned .failed")
                throw LinkProcessError.failed
            }
        }
    }
    
    mutating func updateLinkProcessedAndSave() async {
        //NSLog("updateLinkProcessedAndSave")
        lastProcessTime = Date.secondsSinceReferenceDate
        await save()
        Link.numberOfProcessedLinks += 1
        NSLog("Processed link #\(Link.numberOfProcessedLinks)")
    }
    
    public mutating func saveChildrenIfNeeded() async {
        //print("saveChildrenIfNeeded")
        if await lastProcessTime < Global.global().processTimeThreshold {
            await saveChildren()
        }
    }
    
    mutating func saveChildren() async {
        NSLog("saveChildren")
        for (_, childURL) in await urls() {
            if let _: Link = await database.value(forKey: Link.prefix + childURL) {
            } else {
                var link = Link(url: childURL)
                await link.save()
            }
        }
    }
    
    // MARK: - Saving
    
    public mutating func save() async {
        do {
            if let _: Link = await database.value(forKey: key) {
            } else {
                let hashLink = HashLink(url: url)
                try await database.setValue(hashLink, forKey: HashLink.prefix + hash)
                let siteKey = Site.prefix + url.onionID
                if let _: Site = await database.value(forKey: siteKey) {
                } else if Site.allowed(onionID: url.onionID) {
                    let site = Site(url: url)
                    NSLog("New site: \(url.onionID)")
                    try await database.setValue(site, forKey: siteKey)
                }
            }
            try await database.setValue(self, forKey: key)
        } catch {
            NSLog("Link save failed.")
            try? await Task.sleep(seconds: 1.0)
        }
    }
    
    // MARK: - Helpers
    
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
    
    static func allowed(url: String) -> Bool {
        //NSLog("checking if allowed url")
        if !Site.allowed(onionID: url.onionID) {
            return false
        }
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
            "ejaculate",
            "bitcards",
            "fuck",
            "nacked",
            "porn",
            "video",
            "year",
            "daughter",
            "girl",
            "boy"
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
    
}
