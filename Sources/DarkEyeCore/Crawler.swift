//
//  Database.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/7/22.
//  Copyright © 2022 Amr Aboelela. All rights reserved.
//

import Foundation
import SwiftLevelDB
import Dispatch

public var crawler = Crawler()

public class Crawler {
    public var canRun = true
    
    public func start() {
        NSLog("start")
        crawler.canRun = true
        crawl()
    }
    
    func crawl() {
        NSLog("crawl")
        DispatchQueue.global(qos: .background).async {
            //print("DispatchQueue.global(qos: .background).async")
            Link.crawlNext()
            if self.canRun {
                DispatchQueue.global(qos: .background).async {
                    self.crawl()
                }
            }
        }
    }
    
    public func stop() {
        NSLog("stop")
        crawler.canRun = false
    }
    
    public static func restart() {
        NSLog("restart")
        crawler = Crawler()
        crawler.start()
    }
}
