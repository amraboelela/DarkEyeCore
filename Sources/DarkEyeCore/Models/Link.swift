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

public struct Link: Codable {
    public static let prefix = "link-"
    public static var processTimeThreshold = 1 // any link with last process time smaller, need to be processed
    
    public var url: String
    public var lastProcessTime: Int = 0 // # of seconds since reference date.
    public var numberOfVisits: Int = 0
    public var lastVisitTime: Int = 0 // # of seconds since reference date.
    
    var html: String?
    
    public enum CodingKeys: String, CodingKey {
        case url
        case lastProcessTime
        case numberOfVisits
        case lastVisitTime
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

    public var key: String {
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
    
    var urls: [String] {
        var result = [String]()
        if let html = html, let doc = try? HTMLDocument(string: html) {
            if let nodes = doc.body?.childNodes(ofTypes: [.Element]) {
                for node in nodes {
                    if let elementNode = node.toElement() {
                        let anchorNodes = anchorNodesFrom(node: elementNode)
                        result.append(contentsOf: anchorNodes.compactMap { anchor in
                            if var href = anchor["href"], href.range(of: "#") == nil {
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
                                } else if href.range(of: "http") != nil && href.range(of: ".onion") != nil {
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
    
    var cachedFile: String? {
        let packageRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "Sources/DarkEyeCore/Models/Link.swift", with: ""))
        let fileURL = packageRoot.appendingPathComponent("cache", isDirectory: true).appendingPathComponent(url.hash + ".html")
        if let attr = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            if let fileSize = attr[FileAttributeKey.size] as? NSNumber, fileSize.intValue == 0 {
                print("cachedFile, fileSize == 0")
                return nil
            }
            if let fileDate = attr[FileAttributeKey.modificationDate] as? NSDate {
                let cacheThreashold = Date.days(numberOfDays: 10)
                let secondsDiff = Date().timeIntervalSinceReferenceDate - fileDate.timeIntervalSinceReferenceDate
                if secondsDiff > cacheThreashold {
                    return nil
                }
            }
        }
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }
    
    // MARK: - Factory methods
    
    public static func with(url: String) -> Link {
        return Link(url: url)
    }

    public static func from(key: String) -> Link {
        return Link(url: url(fromKey: key))
    }

    // MARK: - Search
    
    public static func linksToProcess(count: Int) -> [Link] {
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
    
    // MARK: - Crawling
    
    public mutating func crawl(processCount: Int = 10) {
        if lastProcessTime < Link.processTimeThreshold {
            process()
        }
        var links = Link.linksToProcess(count: processCount)
        if links.count == 0 {
            Link.processTimeThreshold = Date.secondsSinceReferenceDate
            process()
            links = Link.linksToProcess(count: processCount)
        }
        for var link in links {
            if !crawler.canRun {
                break
            }
            link.process()
        }
    }
    
    static var numberOfProcessedLinks = 0
    
    public mutating func process() {
        Link.numberOfProcessedLinks += 1
        load()
        for childURL in urls {
            if let _: Link = database[Link.prefix + childURL] {
            } else {
                let link = Link(url: childURL)
                _ = link.save()
            }
        }
        lastProcessTime = Date.secondsSinceReferenceDate
        _ = save()
        Word.index(link: self)
    }
    
    // MARK: - Saving
    
    public func save() -> Bool {
        var newLink = false
        if let _: Link = database[key] {
        } else {
            newLink = true
        }
        database[key] = self
        return newLink
    }
    
    // MARK: - Helpers
    
    mutating func load() {
#if os(Linux)
        if let cachedFile = cachedFile {
            html = cachedFile
        } else {
            let filePath = "cache/" + url.hash + ".html"
            _ = shell("torsocks", "wget", "-O", filePath, url)
            let fileURL = URL(fileURLWithPath: filePath)
            html = try? String(contentsOf: fileURL, encoding: .utf8)
            //print("html: \(html)")
        }
#else
        let packageRoot = URL(fileURLWithPath: #file.replacingOccurrences(of: "Sources/DarkEyeCore/Models/Link.swift", with: ""))
        let fileURL = packageRoot.appendingPathComponent("Resources", isDirectory: true).appendingPathComponent("main_page.html")
        html = try? String(contentsOf: fileURL, encoding: .utf8)
#endif
    }
    
    public static func url(fromKey key: String) -> String {
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
    
}
