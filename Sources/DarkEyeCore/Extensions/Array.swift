//
//  Array.swift
//  SwiftLevelDB
//
//  Created by Amr Aboelela on 4/25/18.
//  Copyright © 2018 Amr Aboelela.
//

import Foundation

@available(macOS 10.15.0, *)
extension Array where Element: Any {
    
    public func asyncFilter(closure: (Element) async -> Bool) async -> Array {
        var result = [Element]()
        for item in self {
            if await closure(item) {
                result.append(item)
            }
        }
        return result
    }
}
