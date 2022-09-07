//
//  Link.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 9/7/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation

extension Link {
    
    static func allowed(url: String) -> Bool {
        //NSLog("checking if allowed url")
        if url.range(of: ":") != nil &&
            url.range(of: "http") == nil {
            return false
        }
        let forbiddenExtensions = [
            ".png",
            ".jpg",
            ".mp4",
            ".zip",
            ".gif",
            ".epub",
            ".nib",
            ".nb0",
            ".php",
            ".pdf",
            ".asc",
            ".webm",
            "?menu=1"
        ]
        for anExtension in forbiddenExtensions {
            if url.suffix(anExtension.count).range(of: anExtension) != nil {
                return false
            }
        }
        let forbiddenTerms = [
            "beverages",
            "money-transfers",
            "music",
            ".media",
            "_media",
            ".php?",
            "2a2a2abbjsjcjwfuozip6idfxsxyowoi3ajqyehqzfqyxezhacur7oyd",
            "222222222xn2ozdb2mjnkjrvcopf5thb6la6yj24jvyjqrbohx5kccid",
            "ejaculate",
            "kxmrdbwcqbgyokjbiv7droplwhxvli3s7yv5xddxgrtajdpdebgzzzqd",
            "bitcards",
            "drugsednqhasbyoyg2oekzbnllbujro54zrogqbf3p6e7qflxti5eeqd",
            "bmj5nf63plhudrvp7lxjaz7fktxvm3heffh364okvfsd3hjx24aalwqd",
            "2cardsowr7u7uvpyrnc5lxuclhb4noj6q2cqf2so7ezg2zufntkjefad",
            "bithacklfxiag2kysa7inceduv3eijqmcbms26w25cmgwuwga4ucbaqd",
            "darkcctef2gtydfcgslrwj6vmu3ktse6pu5el7btczbfhsgiqtsrsoqd",
            "bd7uqvma4x3qfzwpa6pkrgdvtthd5hd2j4qdcvhb2fmpwuen5tdnrmqd",
            "56dlutemceny6ncaxolpn6lety2cqfz5fd64nx4ohevj4a7ricixwzad",
            "deep2v63hwfsupagnmzxyal6jxhtcxdennvcsekkji7qqic4jmjcj3yd",
            "moneye5g34sxtlo3jd2aft6hdphk2dtgvkwnk5taabfrqu75tutmynad",
            "buyreal2xipzjhjfhyztle35dknfexgqrpq4dmzvkc575kzi3vr6bmid",
            "dickvoz3shmr7f4ose43lwrkgljcrvdxy25f4eclk7wl3nls5p5i4nyd",
            "7afbko7mx7o654pbwbwydsiaukzp6wodzb54nf6tkz2h3nmnfa3bszid",
            "hssza6r6fbui4x452ayv3dkeynvjlkzllezxf3aizxppmcfmz2mg7uad",
            "524nypostlyxmdxhplizz3br2jfyjmnf27opin4axhpcemrxzfush2qd",
            "n3irlpzwkcmfochhuswpcrg35z7bzqtaoffqecomrx57n3rd5jc72byd",
            "bobby64o755x3gsuznts6hf6agxqjcz5bop6hs7ejorekbm7omes34ad",
            "courier2w2hawxspntosy3wolvc7g7tcrwhitiu4irrupnpqub2bqxid",
            "deepmej5tgxnpsmdgtvfghdg4dc2jwsddao473qtjmnbvs47dhxn3pid",
            "bananaen6hcopc4iwdt7xbnfjtxszgoe6a5pobfrbfmbol5ihweoxiid",
            "fc3ryhftqfgwyroq7pt63f7jif4jknfrmd3pbdwm4sz3myelf4wfz7qd",
            "fxrx6qvrri4ldt7dhytdvkuakai75bpdlxlmner6zrlkq34rpcqpyqyd",
            "fuck",
            "nacked",
            "porn",
            "video"
        ]
        for term in forbiddenTerms {
            if url.range(of: term) != nil {
                return false
            }
        }
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ":._?/-="))
        if url.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return false
        }
        return true
    }
}
