//
//  HashLink.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/21/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation

public struct HashLink: Codable {
    public static let prefix = "hashlink-"

    public var url: String
    
    // MARK: - Accessors
    
    public var link: Link {
        if let result: Link = database[Link.prefix + url] {
            return result
        }
        return Link(url: url)
    }
}
