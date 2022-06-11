//
//  Word.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 4/20/20.
//  Copyright © 2020 Amr Aboelela. All rights reserved.
//

import Foundation

public struct Word: Codable {
    public static let prefix = "word-"

    public var links: [WordLink]
    
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
