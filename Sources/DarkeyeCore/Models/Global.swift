//
//  Global.swift
//  DarkeyeCore
//
//  Created by Amr Aboelela on 7/1/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation

public struct Global: Codable, Sendable {
    public static let prefix = "global"
    public static var workingDirectory = ""
    
    var processTimeThreshold = 1 // any link with last process time smaller, need to be processed
    var numberOfProcessedSites = 0
    var numberOfProcessedLinks = 0
    var numberOfSearches = 0
    var numberOfViews = 0
    
    public static func global() async -> Global {
        if let result: Global = await database.value(forKey: Global.prefix) {
            return result
        }
        return Global()
    }
    
    static var workingURL: URL {
        if workingDirectory.isEmpty {
            return URL(fileURLWithPath: #file.replacingOccurrences(of: "Sources/DarkeyeCore/Models/Global.swift", with: ""))
        } else {
            return URL(fileURLWithPath: workingDirectory)
        }
    }
    
    static var cacheURL: URL {
        return workingURL.appendingPathComponent("cache", isDirectory: true)
    }
    
    // MARK: - Helpers
    
    func save() async {
        //NSLog("global.save()")
        do {
            try await database.setValue(self, forKey: Global.prefix)
        } catch {
            NSLog("Global save failed.")
            //exit(1)
            try? await Task.sleep(seconds: 1.0)
        }
    }
}
