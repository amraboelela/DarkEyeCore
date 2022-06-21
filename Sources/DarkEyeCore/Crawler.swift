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

public class Crawler: Thread {
    let mainUrl = "http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion/wiki/Main_Page"
    var canRun = true
    
    override init() {
        super.init()
        self.name = "crawler"
    }
    
    public override func main() {
        var link = Link(url: mainUrl)
        while canRun {
            link.crawl()
            //print("Crawler numberOfProcessedLinks: \(Link.numberOfProcessedLinks)")
        }
        print("Crawler numberOfProcessedLinks: \(Link.numberOfProcessedLinks)")
        print("canRun: \(canRun), exiting")
    }
}
