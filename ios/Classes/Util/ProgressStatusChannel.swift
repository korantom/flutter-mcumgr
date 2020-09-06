//
//  ProgressStatusChannel.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 06/09/2020.
//

import Foundation
import Flutter

protocol ProgressStatusChannel {
    var statusEventChannel: FlutterEventChannel { get }
    var progressEventChannel: FlutterEventChannel { get }
    
    var statusStreamHandler: StreamHandler { get }
    var progressStreamHandler: StreamHandler { get }
}

class StreamHandler: NSObject, FlutterStreamHandler {
    
    var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    func send(_ message: Any){
        if let eventSink = self.eventSink {
            eventSink(message)
        }
    }
}
