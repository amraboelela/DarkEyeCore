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
    static let mainUrl = "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Special:AllPages"
    
    // "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
    // "http://5wvugn3zqfbianszhldcqz2u7ulj3xex6i3ha3c5znpgdcnqzn24nnid.onion"
    
    public var processTimeThreshold: Int // any link with last process time smaller, need to be processed
    
    public static func global() async -> Global {
        if let result: Global = await database.value(forKey: Global.prefix) {
            return result
        }
        return Global(processTimeThreshold: 1)
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
