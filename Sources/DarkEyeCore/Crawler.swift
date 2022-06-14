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

public let crawler = Crawler()

public class Crawler: Thread {
    let mainUrl = "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
    var canRun = true
    
    override init() {
        super.init()
        self.name = "crawler"
    }
    
    public override func main() {
        //print("My thread name is: \(Thread.current.name!)")
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
