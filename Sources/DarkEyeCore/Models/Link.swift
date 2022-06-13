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
                            if let url = anchor["href"],
                               url.range(of: "#") == nil,
                               url.range(of: ".onion") != nil {
                                if url.first == "/" {
                                    return base + url
                                } else {
                                    return url
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
    
    // MARK: - Factory methods
    
    public static func with(url: String) -> Link {
        return Link(url: url)
    }

    public static func from(key: String) -> Link {
        return Link(url: url(fromKey: key))
    }

    // MARK: - Search
    
    public static func links(
        withSearchText searchText: String,
        count: Int
    ) -> [Link] {
        var result = [Link]()
        let searchWords = Word.words(fromText: searchText)
        if let firstWord = searchWords.first {
            var wordLinks = [String]()
            database.enumerateKeysAndValues(backward: true, startingAtKey: nil, andPrefix: Word.prefix + firstWord) { (key, word: Word, stop) in
                wordLinks.append(contentsOf: word.links.map { $0.url })
            }
            for wordLink in wordLinks {
                var foundTheSearch = true
                if let link: Link = database[prefix + wordLink] {
                    /*for i in 1..<searchWords.count {
                        let searchWord = searchWords[i]
                        if link.title?.lowercased().range(of: searchWord) == nil {
                            foundTheSearch = false
                            break
                        }
                    }*/
                    if foundTheSearch {
                        result.append(link)
                    }
                }
            }
            result = result.sorted { $0.numberOfVisits > $1.numberOfVisits }
            if result.count > count {
                result.removeLast(result.count - count)
            }
        }
        return result
    }
    
    // MARK: - Processing
    
    public mutating func process() {
        load()
        lastProcessTime = Date.secondsSinceReferenceDate
        _ = save()
        let words = Word.index(link: self)
    }
    
    // MARK: - Saving
    
    public func save() -> Bool {
        var newLink = false
        if let _: Link = database[key] {
        } else {
            newLink = true
            database[key] = self
        }
        return newLink
    }
    
    // MARK: - Helpers
    
    mutating func load() {
#if os(Linux)
        //torsocks wget "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
        shell("torsocks", "wget", url)
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
