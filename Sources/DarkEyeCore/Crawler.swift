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
    public var canRun = true {
        didSet {
            if !canRun && timer != nil {
                timer.invalidate()
            }
        }
    }
    var timer: Timer!
    var running = false
    
    public func start() {
        NSLog("start")
        crawl()
        #if os(Linux)
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.crawl()
        }
        #else
        if #available(macOS 10.12, *) {
            timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
                self?.crawl()
            }
        }
        #endif
    }
    
    func crawl() {
        NSLog("crawl")
        if !running {
            canRun = true
            running = true
            DispatchQueue.global(qos: .background).async {
                Link.crawlNext()
                DispatchQueue.main.async {
                    self.running = false
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
        crawler.start()
    }
}
