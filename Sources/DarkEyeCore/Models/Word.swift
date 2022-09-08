//
//  Word.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 9/7/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation

class Word {
    
    static func words(fromText text: String, lowerCase: Bool = false) -> [String] {
        var result = [String]()
        let whiteCharacters = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\n_()[]-/:{}-+=*&^%$#@!~`?'\";,.<>\\|"))
        let words = text.components(separatedBy: whiteCharacters)
        let commonWords: Set = [
            "and",
            "the",
            "from",
            "for",
            "not",
            "with",
            "but",
            "any",
            "its",
            "can"
        ]
        for word in words {
            if word.count > 0 {
                let finalWords = word.camelCaseWords
                for finalWord in finalWords {
                    if finalWord.count < 16 {
                        let lowerCaseWord = finalWord.lowercased()
                        if commonWords.contains(lowerCaseWord) {
                            continue
                        }
                        if lowerCase {
                            result.append(lowerCaseWord)
                        } else {
                            result.append(finalWord)
                        }
                    }
                }
            }
        }
        return result
    }
    
    static func contextStringFrom(array: [String], atIndex: Int) -> String {
        let wordsCount = 20
        let halfOfCount = wordsCount / 2
        let startIndex = atIndex - halfOfCount < 0 ? 0 : atIndex - halfOfCount
        let endIndex = startIndex + wordsCount >= array.count ? array.count - 1 : startIndex + wordsCount
        return String.from(array: array, startIndex: startIndex, endIdnex: endIndex)
    }
    
    static func allowed(wordsArray: [String]) -> Bool {
        for word in wordsArray {
            if !allowed(word: word) {
                NSLog("Word not allowed: \(word)")
                return false
            }
        }
        let forbiddenWordArrays = [
            ["credit", "card"],
            ["bitcoin", "private", "keys"],
            ["bitcoin", "private", "key"]
        ]
        let wordsSet = Set(wordsArray)
        for forbiddenWordArray in forbiddenWordArrays {
            var arrayAllowed = false
            for forbiddenWord in forbiddenWordArray {
                if !wordsSet.contains(forbiddenWord) {
                    arrayAllowed = true
                }
            }
            if !arrayAllowed {
                return false
            }
        }
        return true
    }
    
    static func allowed(word: String) -> Bool {
        let forbiddenTerms = [
            "fuck",
            "cocaine",
            "music",
            "adult",
            "drug",
            "child",
            "porn",
            "girl",
            "sex",
            "boy",
            "rape",
            "pussy",
            "nude",
            "paypal",
            "prepaid",
            "weed",
            "cannabis",
            "wine",
            "gamble",
            "ejaculate",
            "nacked",
            "cards"
        ]
        for term in forbiddenTerms {
            if word.range(of: term) != nil {
                return false
            }
        }
        return true
    }
}
