//
//  String.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/11/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation

extension String {
    var camelCaseWords: [String] {
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
    
    static func from(array: [String], startIndex: Int, endIdnex:Int) -> String {
        var result = ""
        for i in (startIndex...endIdnex) {
            result += array[i] + " "
        }
        return result.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}
