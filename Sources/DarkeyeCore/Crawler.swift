//
//  Database.swift
//  DarkeyeCore
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
        for mainUrl in Link.mainUrls {
            if let _: Link = await database.value(forKey: Link.prefix + mainUrl) {
                NSLog("crawler init, " + Link.prefix + mainUrl + " already exists")
            } else {
                NSLog("crawler init, creating: " + Link.prefix + mainUrl)
                var link = Link(url: mainUrl)
                await link.save()
            }
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
            //if Date().timeIntervalSinceReferenceDate >= self.startTime {
            NSLog("start")
            await Crawler.shared().canRun = true
            if !self.isRunning {
                await self.crawl()
            }
            //}
        }
    }
    
    func crawl() async {
        //NSLog("crawl")
        if !canRun {
            delegate?.crawlerStopped()
        }
        try? await Task.sleep(seconds: 1.0)
        isRunning = true
        Task(priority: .background) {
            do {
                if try await !Link.crawlNextImportant() {
                    await Site.crawlNext()
                }
                if canRun {
                    await crawl()
                } else {
                    self.delegate?.crawlerStopped()
                    self.isRunning = false
                }
            } catch {
                NSLog("crawl error: \(error)")
                if !canRun {
                    self.delegate?.crawlerStopped()
                }
                self.isRunning = false
            }
        }
    }
    
    public func stop() async {
        NSLog("stop")
        await Crawler.shared().canRun = false
    }
}
