//
//  HashLink.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/21/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation

@available(macOS 10.15.0, *)
public struct HashLink: Codable, Sendable {
    public static let prefix = "hashlink-"

    public var url: String
    
    // MARK: - Accessors
    
    public func link() async -> Link {
        if let result: Link = await database.valueForKey(Link.prefix + url) {
            return result
        }
        return Link(url: url)
    }
    
    // MARK: - Reading
    
    public static func linkWith(hash: String) async -> Link? {
        if let hashLink: HashLink = await database.valueForKey(HashLink.prefix + hash) {
            return await hashLink.link()
        }
        return nil
    }
}
