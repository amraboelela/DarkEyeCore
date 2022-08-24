//
//  Link.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/8/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation
import SwiftLevelDB
import Fuzi
import SwiftEncrypt

public struct Link: Codable {
    public static let prefix = "link-"
    public static var workingDirectory = ""
    
    static var numberOfProcessedLinks = 0
    static var numberOfIndexedLinks = 0
    static let mainUrl = "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
    
    public var url: String
    public var lastProcessTime = 0 // # of seconds since reference date.
    public var failedToLoad = false
    public var lastWordIndex = -1 // last indexed word index
    public var numberOfVisits = 0
    public var lastVisitTime = 0 // # of seconds since reference date.
    public var numberOfReports = 0
    public var blocked: Bool?
    
    public enum CodingKeys: String, CodingKey {
        case url
        case lastProcessTime
        case failedToLoad
        case lastWordIndex
        case numberOfVisits
        case lastVisitTime
        case numberOfReports
        case blocked
    }
    
    // MARK: - Accessors
    
    static var firstKey: String? {
        var result : String?
        database.enumerateKeys(backward: false, startingAtKey: nil, andPrefix: prefix) { key, stop in
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
        let fileURL = Link.cacheURL.appendingPathComponent(hash + ".html")
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
                let cacheFileURL = Link.cacheURL.appendingPathComponent(hash + ".html")
                let tempFileURL = Link.cacheURL.appendingPathComponent(hash + "-temp.html")
                let result = try shell("torsocks", "wget", "-O", tempFileURL.path, url)
                NSLog("torsocks result: \(result)")
                if let fileContent = try? String(contentsOf: tempFileURL, encoding: .utf8), !fileContent.isVacant {
                    _ = try shell("cp", tempFileURL.path, cacheFileURL.path)
                    result = fileContent
                }
                _ = try shell("rm", tempFileURL.path)
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
    
    static var workingURL: URL {
        if Link.workingDirectory.isEmpty {
            return URL(fileURLWithPath: #file.replacingOccurrences(of: "Sources/DarkEyeCore/Models/Link.swift", with: ""))
        } else {
            return URL(fileURLWithPath: Link.workingDirectory)
        }
    }
    
    static var cacheURL: URL {
        return workingURL.appendingPathComponent("cache", isDirectory: true)
    }
    
    // MARK: - Factory methods
    
    static func with(url: String) -> Link {
        return Link(url: url)
    }

    static func from(key: String) -> Link {
        return Link(url: url(fromKey: key))
    }

    // MARK: - Crawling
    
    static func nextLinkToProcess() -> Link? {
        //NSLog("nextLinkToProcess")
        var result: Link? = nil
        let processTimeThreshold = Global.global.processTimeThreshold
        let currentWordIndex = Global.global.currentWordIndex
        database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Link.prefix) { (Key, link: Link, stop) in
            //NSLog("nextLinkToProcess, Key: \(Key)")
            if link.lastProcessTime < processTimeThreshold &&
                link.lastWordIndex < currentWordIndex {
                stop.pointee = true
                result = link
            } else {
                //NSLog("nextLinkToProcess else, Key: \(Key)")
            }
        }
        return result
    }
    
    static func updateCurrentWordIndex() {
        NSLog("updateCurrentWordIndex")
        var global = Global.global
        if global.currentWordIndex < 500 {
            NSLog("global.currentWordIndex < 500")
            global.currentWordIndex += 1
        } else {
            NSLog("global.currentWordIndex < 500 else")
            global.currentWordIndex = 0
            global.processTimeThreshold = Date.secondsSinceReferenceDate
        }
        global.save()
    }
    
    public static func crawlNext() {
        //NSLog("crawlNext")
        if let nextLink = nextLinkToProcess() {
            //print("crawlNext nextLink: \(nextLink.url)")
            Link.process(link: nextLink)
        } else {
            updateCurrentWordIndex()
            if let nextLink = nextLinkToProcess() {
                //NSLog("crawlNext nextLink: \(nextLink.url)")
                Link.process(link: nextLink)
            } else {
                NSLog("can't find any link to process")
            }
        }
    }
    
    static func process(link: Link) {
        NSLog("processing link: \(link.url)")
        if !crawler.canRun || database.closed() {
            return
        }
        var myLink = link
        if myLink.blocked == true || myLink.html == nil {
            Link.remove(url: myLink.url)
            myLink.updateLinkProcessedAndSave()
        } else if myLink.html == nil {
            myLink.updateLinkProcessedAndSave()
        } else {
            myLink.saveChildren()
            switch Word.indexNextWord(link: myLink) {
            case .done:
                myLink.updateLinkIndexedAndSave()
            case .complete:
                myLink.updateLinkProcessedAndSave()
            case .ended:
                NSLog("indexNextWord returned .ended")
            }
        }
    }
    
    mutating func updateLinkIndexedAndSave() {
        lastWordIndex += 1
        save()
        Link.numberOfIndexedLinks += 1
        if Link.numberOfIndexedLinks > 1000 {
            Link.numberOfIndexedLinks = 0
            Link.updateCurrentWordIndex()
        }
        NSLog("indexed link #\(Link.numberOfIndexedLinks)")
    }
    
    mutating func updateLinkProcessedAndSave() {
        NSLog("updateLinkProcessedAndSave")
        lastWordIndex = -1
        lastProcessTime = Date.secondsSinceReferenceDate
        save()
        Link.numberOfProcessedLinks += 1
        NSLog("processed link #\(Link.numberOfProcessedLinks)")
    }
    
    public mutating func saveChildrenIfNeeded() {
        //print("saveChildrenIfNeeded")
        if lastProcessTime < Global.global.processTimeThreshold {
            saveChildren()
        }
    }
    
    mutating func saveChildren() {
        NSLog("saveChildren")
        for (_, childURL) in urls {
            if let _: Link = database[Link.prefix + childURL] {
            } else {
                var link = Link(url: childURL)
                link.save()
            }
        }
    }
    
    // MARK: - Saving
    
    public mutating func save() {
        if let _: Link = database[key] {
        } else {
            let hashLink = HashLink(url: url)
            database[HashLink.prefix + hash] = hashLink
        }
        database[key] = self
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
            ".pdf",
            ".asc",
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
        let filePath = cacheURL.appendingPathComponent(hash + ".html").path
        try? FileManager.default.removeItem(atPath: filePath)
    }
    
}
