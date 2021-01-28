//
//  EPConnectionMessage.swift
//  EpumpFramework
//
//  Created by Fuelmetrics Limited on 28/01/2021.
//

import Foundation

struct EPConnectionMessage: Encodable {
    public var cm: String = "cn"
    public var ch: String = ""
    public var sh: String = ""
    public var sid: String = ""
    public var pn: String = ""
    public var tg: String = ""
    
    public init(){
        self.cm = "cn"
    }
}
