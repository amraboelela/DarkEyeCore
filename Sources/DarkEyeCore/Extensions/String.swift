//
//  String.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/11/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation

extension String {
    var camelCaseWords: [String] {
        if self.count < 10 {
            return [self]
        }
        let result = unicodeScalars.dropFirst().reduce(String(prefix(1))) {
            return CharacterSet.uppercaseLetters.contains($1)
            ? $0 + " " + String($1)
            : $0 + String($1)
        }
        let components = result.components(separatedBy: String.characters.inverted)
        for component in components {
            if component.count == 1 {
                return [self]
            }
        }
        return components
    }
    
    var onionID: String {
        return slice(from: "http://", to: ".onion") ?? ""
    }
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    static func from(array: [String], startIndex: Int, endIdnex:Int) -> String {
        var result = ""
        for i in (startIndex...endIdnex) {
            result += array[i] + " "
        }
        return result.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}
