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
    public static var workingDirectory = ""
    static let mainUrl = "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
    
    public var processTimeThreshold: Int // any link with last process time smaller, need to be processed
    
    public static func global() async -> Global {
        if let result: Global = await database.valueForKey(Global.prefix) {
            return result
        }
        return Global(processTimeThreshold: 1)
    }
    
    static var workingURL: URL {
        if workingDirectory.isEmpty {
            return URL(fileURLWithPath: #file.replacingOccurrences(of: "Sources/DarkEyeCore/Models/Global.swift", with: ""))
        } else {
            return URL(fileURLWithPath: workingDirectory)
        }
    }
    
    static var cacheURL: URL {
        return workingURL.appendingPathComponent("cache", isDirectory: true)
    }
    
    // MARK: - Helpers
    
    func save() async {
        NSLog("global.save()")
        do {
            try await database.setValue(self, forKey: Global.prefix)
        } catch {
            NSLog("Global save failed.")
            //exit(1)
            try? await Task.sleep(seconds: 1.0)
        }
    }
}
