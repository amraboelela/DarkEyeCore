//
//  Word.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 4/20/20.
//  Copyright © 2020 Amr Aboelela. All rights reserved.
//

import Foundation
import Fuzi

public struct Word: Codable {
    public static let prefix = "word-"

    public var links: [WordLink]
    
    public static func text(fromHtml html: String) -> String {
        var result = ""
        do {
            let doc = try HTMLDocument(string: html)
            result += doc.title ?? ""
            if let textNodes = doc.body?.childNodes(ofTypes: [.Element]) {
                for textNode in textNodes {
                    if textNode.toElement()?.tag != "script" {
                        //print("textNode: \(textNode)")
                        result += " " + textNode.stringValue + " "
                    }
                }
            }
        } catch let error {
            print(error)
        }
        return result.replacingOccurrences(
            of: "[ \n]+",
            with: " ",
            options: .regularExpression).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    static func anchorNodesFrom(node: Fuzi.XMLElement) -> [Fuzi.XMLElement] {
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
    
    public static func urls(fromHtml html: String) -> [String] {
        var result = [String]()
        do {
            let doc = try HTMLDocument(string: html)
            if let nodes = doc.body?.childNodes(ofTypes: [.Element]) {
                for node in nodes {
                    if let elementNode = node.toElement() {
                        let anchorNodes = anchorNodesFrom(node: elementNode)
                        result.append(contentsOf: anchorNodes.compactMap { anchor in
                            if let url = anchor["href"], url.range(of: "#") == nil {
                                return url
                            }
                            return nil
                        })
                    }
                }
            }
        } catch let error {
            print(error)
        }
        return result
    }
    
    public static func words(fromText text: String) -> [String] {
        var result = [String]()
        let words = text.lowercased().components(separatedBy: String.characters.inverted)
        for word in words {
            if word.count > 0 {
                result.append(word)
            }
        }
        return result
    }

}

public struct WordLink: Codable {
    var url: String
    var text: String
    var wordCount: Int
    var numberOfVisits: Int = 0
    var lastVisitTime: Int = 0
}
