//
//  ManagerWrapper.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 06/09/2020.
//

import Foundation
import Flutter

class ManagerWrapper: ProgressStatusChannel{
    let statusEventChannel: FlutterEventChannel
    let progressEventChannel: FlutterEventChannel
    
    let statusStreamHandler: StreamHandler
    let progressStreamHandler: StreamHandler
    
    init(name: String, registrar: FlutterPluginRegistrar) {
        self.statusEventChannel = FlutterEventChannel(name: "\(name)/status", binaryMessenger: registrar.messenger())
        self.progressEventChannel = FlutterEventChannel(name: "\(name)/progress", binaryMessenger: registrar.messenger())
        
        self.statusStreamHandler = StreamHandler()
        self.progressStreamHandler = StreamHandler()
        
        statusEventChannel.setStreamHandler(statusStreamHandler)
        progressEventChannel.setStreamHandler(progressStreamHandler)
    }
    
    enum Status: String {
        case inProgress
        case paused
        case failed
        case success
        case canceled
    }
}
