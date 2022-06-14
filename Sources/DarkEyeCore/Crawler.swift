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
    var mainUrl = "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
    var thread: Thread?
    var canRun = true
    
    public func crawl() {
        thread = Thread.init(target: self, selector: #selector(runCrawl), object: nil)
        thread?.start()
    }
    
    @objc public func runCrawl() {
        var link = Link(url: mainUrl)
        var count = 0
        while canRun {
            link.crawl()
            count += 1
            print("crawl count: \(count * 10)")
        }
        print("canRun: \(canRun), exiting")
    }
}
