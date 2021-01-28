//
//  Utility.swift
//  EpumpFramework
//
//  Created by Fuelmetrics Limited on 28/01/2021.
//

import CryptoKit
import Foundation

public class Utility{
    static func randomString(len:Int) -> String {
        let charSet = "0123456789"
        let c = Array(charSet)
        var s:String = ""
        for _ in (1...len) {
            s.append(c[Int(arc4random()) % c.count])
        }
        return s
    }
    
    static func sha1Hash(message: String) -> String {
        let hashed = Insecure.SHA1.hash(data: message.data(using: .utf8)!)
        return hashed.description
    }
}

public enum Comm_Channel: String{
    case Remis = "r"
    case Voucher = "v"
}
