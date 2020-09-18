//
//  ServiceIdentifiers.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 05/09/2020.
//


import Foundation

class ServiceIdentifiers: NSObject {
    //MARK: - UART Identifiers
    static let uartServiceUUIDString                                = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
    static let uartTXCharacteristicUUIDString                       = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
    static let uartRXCharacteristicUUIDString                       = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

    //MARK: - Settings Identifiers
    static let settingServiceUUIDString                             = "4153dc1d-1d21-4cd3-868b-18527460aa02"
    static let settingsCharacteristicUUIDString                     = "db2e7800-fb00-4e01-ae9e-001174007c00"

}
