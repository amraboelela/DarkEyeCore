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
    var running = false
    
    func crawl() {
        NSLog("crawl")
        if !running {
            canRun = true
            running = true
            DispatchQueue.global(qos: .background).async {
                Link.crawlNext()
                DispatchQueue.main.async {
                    self.running = false
                    if self.canRun {
                        DispatchQueue.global(qos: .background).async {
                            self.crawl()
                        }
                    }
                }
            }
        } else {
            NSLog("crawlNext self.canRun && !self.running is false. canRun: \(canRun) running: \(running)")
        }
    }
    
    public func stop() {
        NSLog("stop")
        crawler.canRun = false
    }
    
    public static func restart() {
        NSLog("restart")
        crawler = Crawler()
        crawler.crawl()
    }
}
