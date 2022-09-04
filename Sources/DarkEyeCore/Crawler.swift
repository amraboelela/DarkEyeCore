//
//  Database.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/7/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation
import SwiftLevelDB
import Dispatch

public protocol CrawlerDelegate: AnyObject {
    func crawlerStopped()
}

public class Crawler: @unchecked Sendable {
    static var crawler: Crawler?
    public var canRun = true
    public weak var delegate: CrawlerDelegate?
    var startTime = Date().timeIntervalSinceReferenceDate
    var isRunning = false
    
    init() async {
        if let _: Link = await database.valueForKey(Link.prefix + Link.mainUrl) {
            NSLog("Crawler init, " + Link.prefix + Link.mainUrl + " already exists")
        } else {
            NSLog("Crawler init, creating: " + Link.prefix + Link.mainUrl)
            var link = Link(url: Link.mainUrl)
            await link.save()
        }
    }
    
    public class func shared() async -> Crawler {
        if crawler == nil {
            crawler = await Crawler()
        }
        return crawler!
    }
    
    public func start() async {
        Task(priority: .background) {
            if Date().timeIntervalSinceReferenceDate >= self.startTime {
                NSLog("start")
                await Crawler.shared().canRun = true
                if !self.isRunning {
                    await self.crawl()
                }
            }
        }
    }
    
    func crawl() async {
        NSLog("crawl")
        if !canRun {
            delegate?.crawlerStopped()
        }
        isRunning = true
        await Link.crawlNext()
        Task(priority: .background) {
            if canRun {
                await crawl()
            } else {
                self.delegate?.crawlerStopped()
                self.isRunning = false
            }
        }
    }
    
    public func stop() async {
        NSLog("stop")
        await Crawler.shared().canRun = false
    }
}
