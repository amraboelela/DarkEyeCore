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
    public static var processTimeThreshold = 1 // any link with last process time smaller, need to be processed
    public static var workingDirectory = ""
    
    public var url: String
    public var hash = ""
    public var lastProcessTime = 0 // # of seconds since reference date.
    public var numberOfVisits = 0
    public var lastVisitTime = 0 // # of seconds since reference date.
    public var numberOfReports = 0
    public var blocked: Bool?
    
    public var html: String?
    
    public enum CodingKeys: String, CodingKey {
        case url
        case hash
        case lastProcessTime
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
    
    public var urls: [String] {
        var result = [String]()
        if let html = html, let doc = try? HTMLDocument(string: html) {
            if let nodes = doc.body?.childNodes(ofTypes: [.Element]) {
                for node in nodes {
                    if let elementNode = node.toElement() {
                        let anchorNodes = anchorNodesFrom(node: elementNode)
                        result.append(contentsOf: anchorNodes.compactMap { anchor in
                            if var href = anchor["href"], href.range(of: "#") == nil {
                                if href.range(of: ":") != nil &&
                                    href.range(of: "http") == nil {
                                    return nil
                                }
                                if href.last == "/" {
                                    href = String(href.dropLast())
                                }
                                if href.range(of: "//www.")?.lowerBound == href.startIndex {
                                    href = href.replacingOccurrences(of: "//www", with: "http://www")
                                }
                                if href.range(of: "www.")?.lowerBound == href.startIndex {
                                    href = href.replacingOccurrences(of: "www", with: "http://www")
                                }
                                if href.first == "/" {
                                    return base + href
                                } else if href.range(of: ".onion") != nil {
                                    return href
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
    
    public var rawUrls: [String] {
        var result = [String]()
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
                                if refinedHref.first == "/" || refinedHref.range(of: ".onion") != nil {
                                    return href.htmlEncoded
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
        let thresholdDays = 10
#else
        let thresholdDays = 1000
#endif
        fillHashIfNeeded()
        let fileURL = cacheURL.appendingPathComponent(hash + ".html")
        if let attr = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            if let fileSize = attr[FileAttributeKey.size] as? NSNumber, fileSize.intValue == 0 {
                print("cachedFile, fileSize == 0, url: \(url)")
                return nil
            }
            if let fileDate = attr[FileAttributeKey.modificationDate] as? NSDate {
                let cacheThreashold = Date.days(numberOfDays: thresholdDays)
                let secondsDiff = Date().timeIntervalSinceReferenceDate - fileDate.timeIntervalSinceReferenceDate
                if secondsDiff > cacheThreashold {
                    return nil
                }
            }
        }
        if let result = try? String(contentsOf: fileURL, encoding: .utf8) {
            return result
        } else {
            let oldFileURL = cacheURL.appendingPathComponent(url.hashBase16(numberOfDigits: 32) + ".html")
            if let result = try? String(contentsOf: oldFileURL, encoding: .utf8) {
                print("moving \(oldFileURL.path) to \(fileURL.path)")
                _ = shell("mv", oldFileURL.path, fileURL.path)
                return result
            }
        }
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
    
    static func linksToProcess(count: Int) -> [Link] {
        var result = [Link]()
        database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Link.prefix) { (Key, link: Link, stop) in
            if link.lastProcessTime < processTimeThreshold {
                result.append(link)
                if result.count >= count {
                    stop.pointee = true
                }
            }
        }
        return result
    }
    
    public mutating func crawl(processCount: Int = 20) {
        saveChildrenIfNeeded()
        var links = Link.linksToProcess(count: processCount)
        if links.count == 0 {
            Link.processTimeThreshold = Date.secondsSinceReferenceDate
            saveChildren()
            links = Link.linksToProcess(count: processCount)
        }
        //print("crawl links: \(links.map { $0.url })")
        for link in links {
            Link.process(link: link)
        }
    }
    
    static var numberOfProcessedLinks = 0
    
    static func process(link: Link) {
        if !crawler.canRun || database.closed() {
            return
        }
        var myLink = link
        if link.blocked == true {
            myLink.processAndSave()
        } else {
            myLink.saveChildren()
            if Word.index(link: myLink) {
                myLink.processAndSave()
            } else {
                print("word index link failed")
            }
        }
    }
    
    mutating func processAndSave() {
        lastProcessTime = Date.secondsSinceReferenceDate
        save()
        Link.numberOfProcessedLinks += 1
        print("processed link: \(url)")
    }
    
    public mutating func saveChildrenIfNeeded() {
        if lastProcessTime < Link.processTimeThreshold {
            saveChildren()
        }
    }
    
    mutating func saveChildren() {
        if html == nil {
            loadHTML()
        }
        for childURL in urls {
            //print("process childURL: \(childURL)")
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
            hash = url.hashBase32(numberOfDigits: 12)
            let hashLink = HashLink(url: url)
            database[HashLink.prefix + hash] = hashLink
        }
        database[key] = self
    }
    
    // MARK: - Helpers
    
    public mutating func loadHTML() {
        if let cachedFile = cachedFile() {
            html = cachedFile
        } else {
#if os(Linux)
            fillHashIfNeeded()
            let cacheFileURL = cacheURL.appendingPathComponent(hash + ".html")
            let tempFileURL = cacheURL.appendingPathComponent(hash + "-temp.html")
            _ = shell("torsocks", "wget", "-O", tempFileURL.path, url)
            if let fileContent = try? String(contentsOf: tempFileURL, encoding: .utf8), !fileContent.isVacant {
                _ = shell("cp", tempFileURL.path, cacheFileURL.path)
                html = fileContent
            }
            _ = shell("rm", tempFileURL.path)
#else
            let fileURL = workingURL.appendingPathComponent("Resources", isDirectory: true).appendingPathComponent("main_page.html")
            html = try? String(contentsOf: fileURL, encoding: .utf8)
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
