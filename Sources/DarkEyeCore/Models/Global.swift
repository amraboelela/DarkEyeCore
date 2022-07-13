//
//  Global.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 7/1/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation

public struct Global: Codable {
    public static let prefix = "global"
    public var processTimeThreshold: Int // any link with last process time smaller, need to be processed
    public var currentWordIndex = 0
    
    // MARK: - Accessors
    
    public static var global: Global {
        if let result: Global = database[Global.prefix] {
            return result
        }
        return Global(processTimeThreshold: 1)
    }
    
    // MARK: - Helpers
    
    func save() {
        database[Global.prefix] = self
    }
}
