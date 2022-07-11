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
            NSLog("Crawler init, " + Link.prefix + Link.mainUrl + " already exists")
        } else {
            NSLog("Crawler init, creating: " + Link.prefix + Link.mainUrl)
            var link = Link(url: Link.mainUrl)
            link.save()
            NSLog("ya lahweeeeee")
            database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: Link.prefix) { (Key, link: Link, stop) in
                NSLog("nextLinkToProcess, Key: \(Key)")
                //if link.lastProcessTime < processTimeThreshold &&
                //  link.linkAddedTime < processTimeThreshold {
                //  stop.pointee = true
                //result = link
                /*} else {
                 NSLog("nextLinkToProcess else, Key: \(Key)")
                 }*/
            }
        }
    }
    
    public func start() {
        NSLog("start")
        crawler.canRun = true
        crawl()
    }
    
    func crawl() {
        //NSLog("crawl")
        //reportMemory()
        if !canRun {
            delegate?.crawlerStopped()
        }
        let theFreeMemory = freeMemory()
        NSLog("Free Memory: \(theFreeMemory)")
        if theFreeMemory < 100 {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60.0) {
                self.serialQueue.async {
                    self.crawl()
                }
            }
            return
        }
        serialQueue.async {
            Link.crawlNext()
            if self.canRun {
                //DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5.0) {
                self.serialQueue.async {
                    self.crawl()
                }
                //}
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
