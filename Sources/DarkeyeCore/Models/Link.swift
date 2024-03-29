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

enum Priority: Int, Codable {
    case high
    case medium
    case low
    
    var childPriority: Priority {
        switch self {
        case .high:
            return .medium
        case .medium, .low:
            return .low
        }
    }
}

public struct Link: Codable, Equatable, Sendable {
    public static let prefix = "link-"
    static let mainUrls = [
        "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page",
        "http://torchdeedp3i2jigzjdmfpn5ttjhthh5wbmda2rr3jvqjg5p77c54dqd.onion/search?query=%D8%B5%D8%AD%D9%8A%D9%81%D8%A9+%D8%A7%D9%84%D9%86%D8%A8%D8%A3&action=search",
        "http://haneinhodfxcjcnsm6efuyzdffcrejd7jmstte7hwdvhf67x6okyb2ad.onion"
    ]
    
    static var cachedHtml = [String: String]()
    
    public var url: String
    public var title: String?
    public var lastProcessTime = 0 // # of seconds since reference date.
    public var numberOfVisits = 0
    public var lastVisitTime = 0 // # of seconds since reference date.
    public var numberOfLinks = 1 // # of inbound links
    var priority: Priority? // default is .low
    public var blocked: Bool?
    
    public enum CodingKeys: String, CodingKey {
        case url
        case title
        case lastProcessTime
        case numberOfVisits
        case lastVisitTime
        case numberOfLinks
        case priority
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

    var key: String {
        return Link.prefix + url
    }

    public var date: String {
        return Date.dateStringFrom(timeInterval: TimeInterval(lastProcessTime))
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
    
    func exists() async -> Bool {
        if let _: Link = await database.value(forKey: key) {
            return true
        }
        return false
    }
    
    public func html() async throws -> String? {
        NSLog("html, url: \(url)")
        if let cachedHtml = Link.cachedHtml[url] {
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
                NSLog("html needToRefresh")
                needToRefresh = true
            }
        }
        if result == nil || needToRefresh {
            if await !Crawler.shared().canRun {
                if result != nil {
                    NSLog("html returning current cached file")
                    return result
                } else {
                    NSLog("html throw LinkProcessError.cannotRun")
                    throw LinkProcessError.cannotRun
                }
            }
#if os(Linux)
            do {
                NSLog("calling torsocks")
                let timeout: TimeInterval = result == nil ? 5 * 60 : 60
                if let shellResult = try await shell(timeout: timeout, "torsocks", "wget", "-O", fileURL.path, url) {
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
                    NSLog("exit(1)")
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
    
    public mutating func updateTitle() async {
        var result = ""
        if let html = try? await html(), let doc = try? HTMLDocument(string: html) {
            result += doc.title ?? ""
        }
        result = result.replacingOccurrences(
            of: "[ \n]+",
            with: " ",
            options: .regularExpression).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        title = String(result.prefix(100))
    }
    
    public func text() async -> String {
        var result = ""
        if let html = try? await html(), let doc = try? HTMLDocument(string: html) {
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
        if let html = try? await html(), let doc = try? HTMLDocument(string: html) {
            if let nodes = doc.body?.childNodes(ofTypes: [.Element]) {
                for node in nodes {
                    if let elementNode = node.toElement() {
                        let anchorNodes = anchorNodesFrom(node: elementNode)
                        for anchor in anchorNodes {
                            //result.append(contentsOf: anchorNodes.compactMap { anchor in
                            if let href = anchor["href"], href.range(of: "#") == nil {
                                if !Link.allowed(url: href) {
                                    continue
                                }
                                var refinedHref = href
                                if refinedHref.range(of: "redirect_url=") != nil {
                                    refinedHref = refinedHref.slice(from: "redirect_url=") ?? refinedHref
                                }
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
                                    result.append((href.htmlEncoded, base + refinedHref))
                                } else if refinedHref.range(of: ".onion") != nil &&
                                            Site.allowed(onionID: refinedHref.onionID) {
                                    result.append((href.htmlEncoded, refinedHref))
                                }
                            }
                            //return nil
                        }
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
    
    func isBlocked() async -> Bool {
        return blocked == true || !Link.allowed(url: url)
    }
    
    // MARK: - Factory methods
    
    static func with(url: String) -> Link {
        return Link(url: url)
    }

    static func from(key: String) -> Link {
        return Link(url: url(fromKey: key))
    }

    // MARK: - Crawling
    
    static func importantLinkToProcess() async -> Link? {
        //NSLog("importantLinkToProcess")
        var result: Link?
        let processTimeThreshold = await Global.global().processTimeThreshold
        await database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Link.prefix) { (Key, link: Link, stop) in
            if link.lastProcessTime < processTimeThreshold {
                //NSLog("importantLinkToProcess link.lastProcessTime < processTimeThreshold")
                if let priority = link.priority, priority != .low {
                    //NSLog("importantLinkToProcess priority != .low link: \(link)")
                    result = link
                    stop.pointee = true
                }
            } else {
                //NSLog("nextLinkToProcess else, Key: \(Key)")
            }
        }
        return result
    }
    
    static func nextLinkToProcess() async -> Link? {
        NSLog("nextLinkToProcess")
        var result: Link?
        let processTimeThreshold = await Global.global().processTimeThreshold
        var availableLinks = [Link]()
        await database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Link.prefix) { (Key, link: Link, stop) in
            if link.lastProcessTime < processTimeThreshold {
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
    
    static func crawlNextImportant() async throws -> Bool {
        //NSLog("Link.crawlNextImportant")
        if let link = await Link.importantLinkToProcess() {
            NSLog("Link.crawlNextImportant importantLinkToProcess: \(link)")
            do {
                try await process(link: link)
            }
            catch {
                switch error {
                case LinkProcessError.notAllowed:
                    break
                case LinkProcessError.cannotRun:
                    throw error
                default:
                    NSLog("Link crawlNextImportant error: \(error)")
                }
            }
            let global = await Global.global()
            NSLog("last processed site #\(global.numberOfProcessedSites)")
            return true
        }
        return false
    }
    
    static func crawlNext() async throws {
        NSLog("Link.crawlNext")
        if let nextLink = await nextLinkToProcess() {
            //print("crawlNext nextLink: \(nextLink.url)")
            try await process(link: nextLink)
        } else {
            var global = await Global.global()
            global.processTimeThreshold = Date.secondsSinceReferenceDate
            await global.save()
            NSLog("can't find any link to process")
        }
    }
    
    static func process(link: Link) async throws {
        NSLog("processing link: \(link.url)")
        var myLink = link
        if await link.isBlocked() {
            NSLog("link not allowed")
            myLink.blocked = true
            await myLink.updateLinkProcessedAndSave()
            throw LinkProcessError.notAllowed
        }
        let crawler = await Crawler.shared()
        let dbClosed = await database.closed()
        if !crawler.canRun || dbClosed {
            throw LinkProcessError.cannotRun
        }
        if try await link.html() == nil {
            //NSLog("myLink.html() == nil ")
            await myLink.updateLinkProcessedAndSave()
        } else {
            switch await WordLink.index(link: myLink) {
            case .complete:
                await myLink.saveChildren()
                await myLink.updateTitle()
                await myLink.updateLinkProcessedAndSave()
            case .ended:
                NSLog("indexNextWord returned .ended")
                throw LinkProcessError.cannotRun
            case .notAllowed:
                NSLog("url not allowed")
                myLink.blocked = true
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
        var global = await Global.global()
        global.numberOfProcessedLinks += 1
        await global.save()
        NSLog("processed link #\(global.numberOfProcessedLinks)")
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
            if var link: Link = await database.value(forKey: Link.prefix + childURL) {
                link.numberOfLinks += 1
                //NSLog("link.url: \(link.url)")
                //NSLog("link.numberOfLinks: \(link.numberOfLinks)")
                await link.save()
            } else {
                var link = Link(url: childURL, priority: priority?.childPriority)
                await link.save()
            }
        }
    }
    
    // MARK: - Saving
    
    static func saveLinksWith(searchText: String) async {
        //NSLog("saveLinksWith begin")
        let searchTextEncoded = searchText.lowercased().replacingOccurrences(of: " ", with: "+")
        let searchURLs = [
            "http://torchdeedp3i2jigzjdmfpn5ttjhthh5wbmda2rr3jvqjg5p77c54dqd.onion/search?query=" + searchTextEncoded,
            "http://juhanurmihxlp77nkq76byazcldy2hlmovfu2epvl5ankdibsot4csyd.onion/search/?q=" + searchTextEncoded
        ]
        for searchURL in searchURLs {
            var searchLink = Link(url: searchURL, priority: .high)
            if await !searchLink.exists() {
                //NSLog("wordLinks with searchText, searchLink: \(searchLink)")
                await searchLink.save()
            }
        }
        //NSLog("saveLinksWith end")
    }
    
    public mutating func save() async {
        do {
            if await !exists() {
                let hashLink = HashLink(url: url)
                try await database.setValue(hashLink, forKey: HashLink.prefix + hash)
                let siteKey = Site.prefix + url.onionID
                if let _: Site = await database.value(forKey: siteKey) {
                } else if await !isBlocked() {
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
    
    public mutating func viewing() async {
        NSLog("viewing link: \(url) \(title ?? "")")
        numberOfVisits += 1
        lastVisitTime = Date.secondsSinceReferenceDate
        await save()
        var global = await Global.global()
        global.numberOfViews += 1
        NSLog("numberOfViews: \(global.numberOfViews)")
        await global.save()
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
        if url.range(of: "://") != nil &&
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
            "?menu=1",
            ".svg"
        ]
        for anExtension in forbiddenExtensions {
            if url.suffix(anExtension.count).range(of: anExtension) != nil {
                return false
            }
        }
        var forbiddenTerms = [
            "money-transfers",
            ".media",
            "_media",
            ".php?",
            "User_talk:",
            "/File:"
        ]
        forbiddenTerms.append(contentsOf: Word.forbiddenTerms)
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
