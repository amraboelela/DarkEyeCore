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
    static var numberOfAddedLinks = 0
    static let mainUrl = "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
    
    public var url: String
    public var hash = ""
    public var lastProcessTime = 0 // # of seconds since reference date.
    public var linkAddedTime = 0
    public var failedToLoad = false
    public var numberOfVisits = 0
    public var lastVisitTime = 0 // # of seconds since reference date.
    public var numberOfReports = 0
    public var blocked: Bool?
    
    public var html: String?
    
    public enum CodingKeys: String, CodingKey {
        case url
        case hash
        case lastProcessTime
        case linkAddedTime
        case failedToLoad
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
                                if href.range(of: ":") != nil &&
                                    href.range(of: "http") == nil {
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
    
    var workingURL: URL {
        if Link.workingDirectory.isEmpty {
            return URL(fileURLWithPath: #file.replacingOccurrences(of: "Sources/DarkEyeCore/Models/Link.swift", with: ""))
        } else {
            return URL(fileURLWithPath: Link.workingDirectory)
        }
    }
    
    var cacheURL: URL {
        return workingURL.appendingPathComponent("cache", isDirectory: true)
    }
    
    mutating func cachedFile() -> String? {
#if os(Linux)
        let thresholdDays = 100
#else
        let thresholdDays = 1000
#endif
        fillHashIfNeeded()
        let fileURL = cacheURL.appendingPathComponent(hash + ".html")
        //NSLog("cachedFile fileURL: \(fileURL)")
        if let attr = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            if let fileSize = attr[FileAttributeKey.size] as? NSNumber, fileSize.intValue == 0 {
                //NSLog("cachedFile, fileSize == 0, url: \(url)")
                return nil
            }
            if let fileDate = attr[FileAttributeKey.modificationDate] as? NSDate {
                let cacheThreashold = Date.days(numberOfDays: thresholdDays)
                let secondsDiff = Date().timeIntervalSinceReferenceDate - fileDate.timeIntervalSinceReferenceDate
                if secondsDiff > cacheThreashold {
                    NSLog("secondsDiff > cacheThreashold. cacheThreashold: \(cacheThreashold)")
                    return nil
                }
            }
        }
        if let result = try? String(contentsOf: fileURL, encoding: .utf8) {
            //NSLog("cachedFile return result fileURL: \(fileURL)")
            return result
        }
        //NSLog("cachedFile return nil")
        return nil
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
        database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Link.prefix) { (Key, link: Link, stop) in
            //NSLog("nextLinkToProcess, Key: \(Key)")
            if link.lastProcessTime < processTimeThreshold &&
                link.linkAddedTime < processTimeThreshold {
                stop.pointee = true
                result = link
            } else {
                //NSLog("nextLinkToProcess else, Key: \(Key)")
            }
        }
        return result
    }
    
    static func nextAddedLinkToProcess(includeFailedToLoad: Bool) -> Link? {
        NSLog("nextAddedLinkToProcess")
        var result: Link? = nil
        database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Link.prefix) { (Key, link: Link, stop) in
            if link.linkAddedTime > link.lastProcessTime &&
                (includeFailedToLoad || !link.failedToLoad) {
                stop.pointee = true
                result = link
            }
        }
        return result
    }
    
    public static func crawlNext() {
        //NSLog("crawlNext")
        if let nextLink = nextLinkToProcess() {
            //print("crawlNext nextLink: \(nextLink.url)")
            Link.process(link: nextLink)
        } else if let nextLink = nextAddedLinkToProcess(includeFailedToLoad: false) {
            print("crawlNext nextAddedLinkToProcess: \(nextLink.url)")
            Link.process(link: nextLink)
        } else {
            Global.update(processTimeThreshold: Date.secondsSinceReferenceDate)
            if let nextLink = nextLinkToProcess() {
                //NSLog("crawlNext nextLink: \(nextLink.url)")
                Link.process(link: nextLink)
            } else {
                if let nextLink = nextAddedLinkToProcess(includeFailedToLoad: true) {
                    //print("crawlNext nextAddedLinkToProcess: \(nextLink.url)")
                    Link.process(link: nextLink)
                } else {
                    NSLog("can't find any link to process!")
                }
            }
        }
    }
    
    static func process(link: Link) {
        NSLog("processing link: \(link.url)")
        if !crawler.canRun || database.closed() {
            return
        }
        var myLink = link
        if myLink.blocked == true {
            crawler.serialQueue.async {
                myLink.updateAndSave()
            }
        } else {
            if myLink.html == nil {
                if !myLink.loadHTML() {
                    myLink.failedToLoad = true
                    myLink.save()
                    NSLog("failedToLoad url: \(myLink.url)")
                }
            }
            myLink.saveChildren()
            if Word.index(link: myLink) {
                crawler.serialQueue.async {
                    myLink.updateAndSave()
                }
            } else {
                //print("word index returned false")
            }
        }
    }
    
    mutating func updateLinkAddedAndSave() {
        linkAddedTime = Date.secondsSinceReferenceDate
        save()
        Link.numberOfAddedLinks += 1
        NSLog("added link #\(Link.numberOfAddedLinks): \(url)")
    }
    
    mutating func updateAndSave() {
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
        for (_, childURL) in urls {
            crawler.serialQueue.async {
                //print("process childURL: \(childURL)")
                if let _: Link = database[Link.prefix + childURL] {
                } else {
                    var link = Link(url: childURL)
                    link.save()
                }
            }
        }
    }
    
    // MARK: - Saving
    
    public mutating func save() {
        if let _: Link = database[key] {
        } else {
            hash = url.hashBase32(numberOfDigits: 12)
            let hashLink = HashLink(url: url)
            database[HashLink.prefix + hash] = hashLink
        }
        database[key] = self
    }
    
    // MARK: - Helpers
    
    public mutating func loadHTML() -> Bool {
        if let cachedFile = cachedFile() {
            html = cachedFile
            return true
        } else {
#if os(Linux)
            let linkFileURL = cacheURL.appendingPathComponent(hash + ".link")
            do {
                if let data = url.data(using: .utf8) {
                    try data.write(to: linkFileURL)
                    self.updateLinkAddedAndSave()
                }
            } catch {
                NSLog("loadHTML addeding link error: \(error)")
            }
            return false
#else
            let fileURL = workingURL.appendingPathComponent("Resources", isDirectory: true).appendingPathComponent("main_page.html")
            html = try? String(contentsOf: fileURL, encoding: .utf8)
            return true
#endif
        }
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
    
    mutating func fillHashIfNeeded() {
        if hash.isEmpty {
            hash = url.hashBase32(numberOfDigits: 12)
        }
    }
    
}
