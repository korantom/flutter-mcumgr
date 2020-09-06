//
//  FirmwareImage.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 06/09/2020.
//

import Foundation
import McuManager

struct FirmwareImage: Codable {
    
    let slot: Int
    let version:String
    let hash: [UInt8]
    let hashStr: String
    let flags: Dictionary<String, Bool>
    
    init(slot: Int, version: String, hash: [UInt8], flags: Dictionary<String, Bool>) {
        self.slot = slot
        self.version = version
        self.hash = hash
        self.hashStr = Data(hash).hexString
        self.flags = flags
    }
    
    init(image: McuMgrImageStateResponse.ImageSlot){
        self.init(slot: Int(image.slot),
                  version: image.version,
                  hash: image.hash,
                  flags: ["active":image.active,
                          "bootable":image.bootable,
                          "confirmed":image.confirmed,
                          "pending":image.pending,
                          "permanent":image.permanent,])
    }
}
