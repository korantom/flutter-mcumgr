//
//  FlutterMcuMgrLogDelegate.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 17/09/2020.
//

import Foundation
import os


public enum FlutterMcuMgrLogLevel: Int {
    case debug       = 0
    case verbose     = 1
    case info        = 5
    case application = 10
    case warning     = 15
    case error       = 20
    
    public var name: String {
        switch self {
        case .debug:       return "D"
        case .verbose:     return "V"
        case .info:        return "I"
        case .application: return "A"
        case .warning:     return "W"
        case .error:       return "E"
        }
    }
}

/// The log category indicates the component that created the log entry.
public enum FlutterMcuMgrLogCategory: String {
    case settingsManager = "SettingsServiceManager"
    case uartManager = "UARTServiceManager"
    case flutterPlugin = "SwiftFlutterMcumgrPlugin"
}

/// The Logger delegate.
public protocol FlutterMcuMgrLogDelegate: class {
    
    /// Provides the delegate with content intended to be logged.
    ///
    /// - parameters:
    ///   - msg: The text to log.
    ///   - category: The log category.
    ///   - level: The priority of the text being logged.
    func log(_ msg: String,
             ofCategory category: FlutterMcuMgrLogCategory,
             atLevel level: FlutterMcuMgrLogLevel)
    
    func log(_ msg: String,
             atLevel level: FlutterMcuMgrLogLevel)
}

extension FlutterMcuMgrLogLevel {
    
    /// Mapping from Mcu log levels to system log types.
    @available(iOS 10.0, *)
    var type: OSLogType {
        switch self {
        case .debug:       return .debug
        case .verbose:     return .debug
        case .info:        return .info
        case .application: return .default
        case .warning:     return .error
        case .error:       return .fault
        }
    }
    
}

extension FlutterMcuMgrLogCategory {
    
    @available(iOS 10.0, *)
    var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
    }
    
}
