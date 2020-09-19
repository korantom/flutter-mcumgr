//
//  ServiceManager.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 19/09/2020.
//

import Foundation
import CoreBluetooth
import os

protocol ServiceManager {
    var serviceUUID: CBUUID { get }
    var RXCharacteristicsUUIDs: [CBUUID] { get }
    var TXCharacteristicsUUIDs: [CBUUID] { get }
    var characteristicsUUIDs: [CBUUID] { get }
    
    var characteristics: [CBUUID:CBCharacteristic] { get set }
    
    var bluetoothPeripheral: CBPeripheral? { get set }
    
    var onDidUpdateValueForCharacterictic: ((Any) -> Void)? { get set }
    var onDidWriteToCharacteristic: ((Any) -> Void)? { get set }
    
}
extension ServiceManager{
    var characteristicsUUIDs: [CBUUID] {
        return self.RXCharacteristicsUUIDs + self.TXCharacteristicsUUIDs
    }
}
