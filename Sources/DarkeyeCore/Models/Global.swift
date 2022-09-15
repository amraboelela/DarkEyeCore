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
    static let mainUrls = [
        "http://torchdeedp3i2jigzjdmfpn5ttjhthh5wbmda2rr3jvqjg5p77c54dqd.onion/search?query=%D8%B5%D8%AD%D9%8A%D9%81%D8%A9+%D8%A7%D9%84%D9%86%D8%A8%D8%A3&action=search",
        "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page",
        "http://haneinhodfxcjcnsm6efuyzdffcrejd7jmstte7hwdvhf67x6okyb2ad.onion"
    ]
    
    //"http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
    //"http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Special:SpecialPages"
    //"http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Special:AllPages"
    static let mainOnionID = "torchdeedp3i2jigzjdmfpn5ttjhthh5wbmda2rr3jvqjg5p77c54dqd.onion"
    
    //"zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad"
    
    // "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
    
    public var processTimeThreshold = 1 // any link with last process time smaller, need to be processed
    public var numberOfProcessedSites = 0
    public var numberOfProcessedLinks = 0
    
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
