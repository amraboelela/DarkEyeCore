//
//  String.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/11/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation

extension String {
    func camelCaseToWords() -> String {
        return unicodeScalars.dropFirst().reduce(String(prefix(1))) {
            return CharacterSet.uppercaseLetters.contains($1)
            ? $0 + " " + String($1)
            : $0 + String($1)
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
