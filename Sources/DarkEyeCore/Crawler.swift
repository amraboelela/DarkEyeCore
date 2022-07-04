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

public protocol CrawlerDelegate: AnyObject {
    func crawlerStopped()
}

public class Crawler {
    public let serialQueue = DispatchQueue(label: "org.darkeye.crawler", qos: .background)
    public var canRun = true
    public weak var delegate: CrawlerDelegate?
    
    init() {
        if let _: Link = database[Link.prefix + Link.mainUrl] {
        } else {
            var link = Link(url: Link.mainUrl)
            link.save()
        }
    }
    
    public func start() {
        NSLog("start")
        crawler.canRun = true
        crawl()
    }
    
    func crawl() {
        NSLog("crawl")
        if !canRun {
            delegate?.crawlerStopped()
        }
        serialQueue.async {
            Link.crawlNext()
            if self.canRun {
                self.serialQueue.async {
                    self.crawl()
                }
            } else {
                self.delegate?.crawlerStopped()
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
