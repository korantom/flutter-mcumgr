//
//  UARTServiceManager.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 20/09/2020.
//

import Foundation
import CoreBluetooth
import os

struct TextCommand: Equatable {
    var title: String { text }
    var data: Data {
        text.data(using: .utf8)!
    }

    let text: String
    var eol: String = "\n"
}

class UARTServiceManager: NSObject, ServiceManager{
    var serviceUUID: CBUUID = CBUUID(string: ServiceIdentifiers.uartServiceUUIDString)
    var RXCharacteristicsUUIDs: [CBUUID] = []
    var TXCharacteristicsUUIDs: [CBUUID] = []
    var characteristics: [CBUUID : CBCharacteristic] = [:]
    var bluetoothPeripheral: CBPeripheral?
    
    let UARTRXCharacteristicUUID: CBUUID
    let UARTTXCharacteristicUUID: CBUUID
    
    var onDidUpdateValueForCharacterictic: ((Any) -> Void)?
    var onDidWriteToCharacteristic: ((Any) -> Void)?
    
    override init() {
        self.UARTRXCharacteristicUUID = CBUUID(string: ServiceIdentifiers.uartRXCharacteristicUUIDString)
        self.UARTTXCharacteristicUUID = CBUUID(string: ServiceIdentifiers.uartTXCharacteristicUUIDString)
        
        self.RXCharacteristicsUUIDs = [UARTRXCharacteristicUUID]
        self.TXCharacteristicsUUIDs = [UARTTXCharacteristicUUID]
    }
    
    
    func send(command aCommand: TextCommand, result: @escaping FlutterResult) {
        
        guard let uartRXCharacteristic = characteristics[self.UARTRXCharacteristicUUID] else {
            result(FlutterError(code: "UART_CHARACTERISTIC_NOT_FOUND",
                                message: "UART RX Characteristic not found",
                                details: ""))
            return
        }
        
        let type: CBCharacteristicWriteType = uartRXCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        let mtu = bluetoothPeripheral?.maximumWriteValueLength(for: type) ?? 20
        
        onDidUpdateValueForCharacterictic = type == .withResponse ? { (reply) in result(reply)} : nil
        
        let data = aCommand.data.split(by: mtu)
        data.forEach {
            self.bluetoothPeripheral!.writeValue($0, for: uartRXCharacteristic, type: type)
        }
        
        log("Writing to characteristic: \(uartRXCharacteristic.uuid.uuidString)", atLevel: .verbose)
        let typeAsString = type == .withoutResponse ? ".withoutResponse" : ".withResponse"
        log( "peripheral.writeValue(0x\(aCommand.data.hexString), for: \(uartRXCharacteristic.uuid.uuidString), type: \(typeAsString))", atLevel: .verbose)
        log("Sent command: \(aCommand.title)", atLevel: .verbose)
        
    }
    
}

extension UARTServiceManager: FlutterMcuMgrLogDelegate {
    
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
            os_log("%{public}@", log: FlutterMcuMgrLogCategory.uartManager.log, type: level.type, msg)
        } else {
            NSLog("%@", msg)
        }
    }
    
}
