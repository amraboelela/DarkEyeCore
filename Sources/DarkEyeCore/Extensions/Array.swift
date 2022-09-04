//
//  Array.swift
//  SwiftLevelDB
//
//  Created by Amr Aboelela on 9/3/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation

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
    
    public func asyncCompactMap<Element2>(closure: (Element) async -> Element2?) async -> [Element2] {
        var result = [Element2]()
        for item in self {
            if let item2 = await closure(item) {
                result.append(item2)
            }
        }
        return result
    }
}
