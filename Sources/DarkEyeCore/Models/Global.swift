//
//  Global.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 7/1/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation

public struct Global: Codable, Sendable {
    public static let prefix = "global"
    public var processTimeThreshold: Int // any link with last process time smaller, need to be processed
    public var currentWordIndex = 0
    
    public static func global() async -> Global {
        if let result: Global = await database.valueForKey(Global.prefix) {
            return result
        }
        return Global(processTimeThreshold: 1)
    }
    
    // MARK: - Helpers
    
    func save() async {
        NSLog("global.save()")
        do {
            try await database.setValue(self, forKey: Global.prefix)
        } catch {
            NSLog("Global save failed. Exiting")
            exit(1)
        }
    }
}
