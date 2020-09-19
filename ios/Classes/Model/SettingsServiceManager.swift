//
//  SettingsServiceManager.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 20/09/2020.
//

import Foundation
import CoreBluetooth
import os

class SettingsServiceManager: NSObject, ServiceManager{
    
    var serviceUUID: CBUUID = CBUUID(string: ServiceIdentifiers.settingServiceUUIDString)
    var RXCharacteristicsUUIDs: [CBUUID] = []
    var TXCharacteristicsUUIDs: [CBUUID] = []
    var characteristics: [CBUUID : CBCharacteristic] = [:]
    var bluetoothPeripheral: CBPeripheral?
    
    let settingsCharacteristicUUID: CBUUID
    
    var onDidUpdateValueForCharacterictic: ((Any) -> Void)?
    var onDidWriteToCharacteristic: ((Any) -> Void)?
    
    override init() {
        self.settingsCharacteristicUUID = CBUUID(string: ServiceIdentifiers.settingsCharacteristicUUIDString)
        self.RXCharacteristicsUUIDs = [settingsCharacteristicUUID]
    }
    
    func read(result: @escaping FlutterResult) {
        log("read", atLevel: .info)
        
        guard let settingsCharacteristic = characteristics[self.settingsCharacteristicUUID] else {
            result(FlutterError(code: "SETTINGS_CHARACTERISTIC_NOT_FOUND",
                                message: "Settings Characteristic not found",
                                details: ""))
            return
        }
        
        let type: CBCharacteristicWriteType = settingsCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        onDidUpdateValueForCharacterictic = type == .withResponse ? { (reply) in result(reply)} : nil
        
        log("Reading from characteristic: \(settingsCharacteristic.uuid.uuidString)", atLevel: .verbose)
        self.bluetoothPeripheral!.readValue(for: settingsCharacteristic)
    }
    
    func send(setting: String, result: @escaping FlutterResult) {
        log("send", atLevel: .info)
        
        guard let settingsCharacteristic = characteristics[self.settingsCharacteristicUUID] else {
            result(FlutterError(code: "SETTINGS_CHARACTERISTIC_NOT_FOUND",
                                message: "Settings Characteristic not found",
                                details: ""))
            return
        }
        
        let type: CBCharacteristicWriteType = settingsCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        onDidWriteToCharacteristic = type == .withResponse ? { (reply) in result(reply)} : nil
        
        //Fixme
        //let mtu = bluetoothPeripheral?.maximumWriteValueLength(for: type) ?? 20
        let mtu = 128
        let data = setting.data(using: .utf8)!.split(by: mtu)
        
        data.forEach {
            self.bluetoothPeripheral!.writeValue($0, for: settingsCharacteristic, type: type)
        }
        
        log("Writing to characteristic: \(settingsCharacteristic.uuid.uuidString)", atLevel: .verbose)
        let typeAsString = type == .withoutResponse ? ".withoutResponse" : ".withResponse"
        log( "peripheral.writeValue(0x\(setting.data(using: .utf8)!.hexString), for: \(settingsCharacteristic.uuid.uuidString), type: \(typeAsString))", atLevel: .verbose)
        log("Sent: \(setting)", atLevel: .verbose)
        
    }
    
}


extension SettingsServiceManager: FlutterMcuMgrLogDelegate {
    
    public func log(_ msg: String,
                    ofCategory category: FlutterMcuMgrLogCategory,
                    atLevel level: FlutterMcuMgrLogLevel) {
        
        if #available(iOS 10.0, *) {
            os_log("%{public}@", log: category.log, type: level.type, msg)
        } else {
            NSLog("%@", msg)
        }
    }
    
    
    public func log(_ msg: String, atLevel level: FlutterMcuMgrLogLevel) {
        
        if #available(iOS 10.0, *) {
            os_log("%{public}@", log: FlutterMcuMgrLogCategory.settingsManager.log, type: level.type, msg)
        } else {
            NSLog("%@", msg)
        }
    }
    
}
