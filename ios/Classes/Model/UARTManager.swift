//
//  UARTManager.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 06/09/2020.
//

import Foundation
import CoreBluetooth
import McuManager
import os.log


struct TextCommand: Equatable {
    var title: String { text }
    var data: Data {
        text.data(using: .utf8)!
    }
    
    let text: String
    var eol: String = "\n"
}

class UARTManager: NSObject{
    
    let UARTServiceUUID: CBUUID
    let UARTRXCharacteristicUUID: CBUUID
    let UARTTXCharacteristicUUID: CBUUID
    
    var bluetoothPeripheral: CBPeripheral?
    private var uartRXCharacteristic: CBCharacteristic?
    private var uartTXCharacteristic: CBCharacteristic?
    
    private var onReceiveReply: ((String) -> Void)?
    
    override init() {
        self.UARTServiceUUID          = CBUUID(string: ServiceIdentifiers.uartServiceUUIDString)
        self.UARTTXCharacteristicUUID = CBUUID(string: ServiceIdentifiers.uartTXCharacteristicUUIDString)
        self.UARTRXCharacteristicUUID = CBUUID(string: ServiceIdentifiers.uartRXCharacteristicUUIDString)
    }
    
    
    func send(command aCommand: TextCommand, result: @escaping FlutterResult) {
        
        guard let uartRXCharacteristic = self.uartRXCharacteristic else {
            result(FlutterError(code: "UART_CHARACTERISTIC_NOT_FOUND",
                                message: "UART RX Characteristic not found",
                                details: ""))
            return
        }
        
        let type: CBCharacteristicWriteType = uartRXCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        let mtu = bluetoothPeripheral?.maximumWriteValueLength(for: type) ?? 20
        
        onReceiveReply = type == .withResponse ? { (reply) in result(reply)} : nil
        
        let data = aCommand.data.split(by: mtu)
        data.forEach {
            self.bluetoothPeripheral!.writeValue($0, for: uartRXCharacteristic, type: type)
        }
        
        log("Writing to characteristic: \(uartRXCharacteristic.uuid.uuidString)", ofCategory: .default, atLevel: .verbose)
        let typeAsString = type == .withoutResponse ? ".withoutResponse" : ".withResponse"
        log( "peripheral.writeValue(0x\(aCommand.data.hexString), for: \(uartRXCharacteristic.uuid.uuidString), type: \(typeAsString))", ofCategory: .default, atLevel: .verbose)
        log("Sent command: \(aCommand.title)", ofCategory: .default, atLevel: .verbose)
        
    }
    
}

extension UARTManager: CBPeripheralDelegate{
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            log("Service discovery failed", ofCategory: .default, atLevel: .verbose)
            log(error!.localizedDescription.description, ofCategory: .default, atLevel: .verbose)
            return
        }
        
        log("Services discovered",ofCategory: .default, atLevel: .verbose)
        
        for aService: CBService in peripheral.services! {
            if aService.uuid.isEqual(UARTServiceUUID) {
                log("Nordic UART Service found",ofCategory: .default, atLevel: .verbose)
                log("Discovering characteristics...",ofCategory: .default, atLevel: .verbose)
                log("peripheral.discoverCharacteristics(nil, for: \(aService.uuid.uuidString))",ofCategory: .default, atLevel: .verbose)
                bluetoothPeripheral!.discoverCharacteristics(nil, for: aService)
                return
            }
        }
        
        //No UART service discovered
        log("UART Service not found. Try to turn bluetooth Off and On again to clear the cache.",ofCategory: .default, atLevel: .verbose)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            log("Characteristics discovery failed",ofCategory: .default, atLevel: .verbose)
            log(error!.localizedDescription.description, ofCategory: .default, atLevel: .verbose)
            return
        }
        log( "Characteristics discovered",ofCategory: .default, atLevel: .verbose)
        
        if service.uuid.isEqual(UARTServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid.isEqual(UARTTXCharacteristicUUID) {
                    log( "TX Characteristic found",ofCategory: .default, atLevel: .verbose)
                    uartTXCharacteristic = aCharacteristic
                } else if aCharacteristic.uuid.isEqual(UARTRXCharacteristicUUID) {
                    log( "RX Characteristic found",ofCategory: .default, atLevel: .verbose)
                    uartRXCharacteristic = aCharacteristic
                }
            }
            //Enable notifications on TX Characteristic
            if (uartTXCharacteristic != nil && uartRXCharacteristic != nil) {
                log( "Enabling notifications for \(uartTXCharacteristic!.uuid.uuidString)",ofCategory: .default, atLevel: .verbose)
                log( "peripheral.setNotifyValue(true, for: \(uartTXCharacteristic!.uuid.uuidString))",ofCategory: .default, atLevel: .verbose)
                bluetoothPeripheral!.setNotifyValue(true, for: uartTXCharacteristic!)
            } else {
                log( "UART service does not have required characteristics. Try to turn Bluetooth Off and On again to clear cache.",ofCategory: .default, atLevel: .verbose)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            log("Enabling notifications failed", ofCategory: .default, atLevel: .verbose)
            log(error!.localizedDescription.description, ofCategory: .default, atLevel: .verbose)
            return
        }
        
        if characteristic.isNotifying {
            log("Notifications enabled for characteristic: \(characteristic.uuid.uuidString)", ofCategory: .default, atLevel: .verbose)
        } else {
            log("Notifications disabled for characteristic: \(characteristic.uuid.uuidString)", ofCategory: .default, atLevel: .verbose)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            log("Writing value to characteristic has failed", ofCategory: .default, atLevel: .verbose)
            log(error!.localizedDescription.description, ofCategory: .default, atLevel: .verbose)
            return
        }
        log("Data written to characteristic: \(characteristic.uuid.uuidString)", ofCategory: .default, atLevel: .verbose)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            log("Writing value to descriptor has failed", ofCategory: .default, atLevel: .verbose)
            log(error!.localizedDescription.debugDescription, ofCategory: .default, atLevel: .verbose)
            return
        }
        log("Data written to descriptor: \(descriptor.uuid.uuidString)", ofCategory: .default, atLevel: .verbose)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            log( "Updating characteristic has failed", ofCategory: .default, atLevel: .verbose)
            log( error!.localizedDescription.description, ofCategory: .default, atLevel: .verbose)
            return
        }
        
        // try to log a friendly string of received bytes if they can be parsed as UTF, ofCategory: .default, atLevel: .verbose)
        guard let bytesReceived = characteristic.value else {
            log( "Notification received from: \(characteristic.uuid.uuidString), with empty value", ofCategory: .default, atLevel: .verbose)
            log( "Empty packet received", ofCategory: .default, atLevel: .verbose)
            return
        }
        
        log( "Notification received from: \(characteristic.uuid.uuidString), with value: 0x\(bytesReceived.hexString)", ofCategory: .default, atLevel: .verbose)
        if let validUTF8String = String(data: bytesReceived, encoding: .utf8) {
            log( "\"\(validUTF8String)\" received", ofCategory: .default, atLevel: .verbose)
            onReceiveReply?(validUTF8String)
        } else {
            log( "\"0x\(bytesReceived.hexString)\" received", ofCategory: .default, atLevel: .verbose)
            onReceiveReply?(bytesReceived.hexString)
        }
        onReceiveReply = nil
    }
    
}


extension UARTManager: McuMgrLogDelegate {
    
    public func log(_ msg: String,
                    ofCategory category: McuMgrLogCategory,
                    atLevel level: McuMgrLogLevel) {
        if #available(iOS 10.0, *) {
            os_log("%{public}@", log: category.log, type: level.type, msg)
        } else {
            NSLog("%@", msg)
        }
    }
    
}
