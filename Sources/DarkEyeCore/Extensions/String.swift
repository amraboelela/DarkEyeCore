//
//  String.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/11/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

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
    
    func MD5(string: String) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: length)
        
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }

    var hash: String {
        let md5Data = MD5(string: self)
        let md5Hex = md5Data.map { String(format: "%02hhx", $0) }.joined()
        return md5Hex.suffix(32).lowercased()
    }
    
    static func from(array: [String], startIndex: Int, endIdnex:Int) -> String {
        var result = ""
        for i in (startIndex...endIdnex) {
            result += array[i] + " "
        }
        return result.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}
