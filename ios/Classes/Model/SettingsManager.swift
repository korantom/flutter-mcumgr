//
//  SettingsManager.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 17/09/2020.
//

import Foundation
import CoreBluetooth
import os.log


class SettingsManager: NSObject{
    
    let settingsServiceUUID: CBUUID
    let settingsCharacteristicUUID: CBUUID
    
    var bluetoothPeripheral: CBPeripheral?{
        didSet{
            bluetoothPeripheral?.delegate = self
        }
    }
    private var settingsCharacteristic: CBCharacteristic?
    
    private var onDidUpdateValueForCharacterictic: ((Any) -> Void)? //TODO: rename
    private var onDidWriteToCharacteristic: ((Any) -> Void)?
    
    override init() {
        self.settingsServiceUUID          = CBUUID(string: ServiceIdentifiers.settingServiceUUIDString)
        self.settingsCharacteristicUUID   = CBUUID(string: ServiceIdentifiers.settingsCharacteristicUUIDString)
    }
    
    func read(result: @escaping FlutterResult) {
        log("read", atLevel: .info)
        
        guard let settingsCharacteristic = self.settingsCharacteristic else {
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
        
        guard let settingsCharacteristic = self.settingsCharacteristic else {
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

extension SettingsManager: CBPeripheralDelegate{

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard error == nil else {
            log("didDiscoverServices failed", atLevel: .info)
            log(error!.localizedDescription.description, ofCategory: .settingsManager, atLevel: .verbose)
            return
        }

        log("didDiscoverServices", ofCategory: .settingsManager, atLevel: .info)

        for aService: CBService in peripheral.services! {
            if aService.uuid.isEqual(settingsServiceUUID) {
                log("Settings Service found", atLevel: .verbose)
                log("Discovering characteristics...", atLevel: .verbose)
                log("peripheral.discoverCharacteristics(nil, for: \(aService.uuid.uuidString))", atLevel: .verbose)
                bluetoothPeripheral!.discoverCharacteristics(nil, for: aService)
                return
            }
        }

        log("Settings Service not found", atLevel: .info)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard error == nil else {
            log("didDiscoverCharacteristicsFor failed", atLevel: .info)
            log(error!.localizedDescription.description, atLevel: .verbose)
            return
        }
        
        log("didDiscoverCharacteristicsFor", atLevel: .info)

        if service.uuid.isEqual(settingsServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid.isEqual(settingsCharacteristicUUID) {
                    log( "Settings Characteristic found", atLevel: .verbose)
                    settingsCharacteristic = aCharacteristic
                }
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            log("didWriteValueFor characteristic failed", atLevel: .info)
            log(error!.localizedDescription.description, atLevel: .verbose)
            onDidWriteToCharacteristic?(FlutterError(code: "WRITE_TO_CHARACTERISTIC_ERROR",
                                                     message: "Failed to write value to characteristic",
                                                     details: error!.localizedDescription.description))
            onDidWriteToCharacteristic = nil
            return
        }
        
        log("didWriteValueFor characteristic", ofCategory: .settingsManager, atLevel: .info)
        onDidWriteToCharacteristic?(true)
        onDidWriteToCharacteristic = nil
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        
        guard error == nil else {
            log("didWriteValueFor descriptor failed", atLevel: .info)
            log(error!.localizedDescription.description, atLevel: .verbose)
            return
        }
        
        log("didWriteValueFor descriptor", ofCategory: .settingsManager, atLevel: .info)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            log( "didUpdateValueFor characteristic failed", atLevel: .info)
            log( error!.localizedDescription.description, atLevel: .verbose)
            onDidUpdateValueForCharacterictic?(FlutterError(code: "UPDATE_VALUE_FOR_CHARACTERISTIC_ERROR",
                                         message: "Failed to update value for characteristic",
                                         details: error!.localizedDescription.description))
            onDidUpdateValueForCharacterictic = nil
            return
        }
        
        log( "didUpdateValueFor characteristic", atLevel: .info)

        guard let bytesReceived = characteristic.value else {
            log( "Notification received from: \(characteristic.uuid.uuidString), with empty value", atLevel: .verbose)
            log( "Empty packet received", atLevel: .verbose)
            onDidUpdateValueForCharacterictic?("")
            onDidUpdateValueForCharacterictic = nil
            return
        }

        log( "Notification received from: \(characteristic.uuid.uuidString), with value: 0x\(bytesReceived.hexString)", atLevel: .verbose)
        if let validUTF8String = String(data: bytesReceived, encoding: .utf8) {
            log( "\"\(validUTF8String)\" received", atLevel: .verbose)
            onDidUpdateValueForCharacterictic?(validUTF8String)
        } else {
            log( "\"0x\(bytesReceived.hexString)\" received", atLevel: .verbose)
            onDidUpdateValueForCharacterictic?(bytesReceived.hexString)
        }
        onDidUpdateValueForCharacterictic = nil
    }
    
}


extension SettingsManager: FlutterMcuMgrLogDelegate {
    
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
