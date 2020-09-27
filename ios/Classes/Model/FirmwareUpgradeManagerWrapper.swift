//
//  FirmwareUpgradeManagerWrapper.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 06/09/2020.
//

import Foundation
import McuManager

class FirmwareUpgradeManagerWrapper: ManagerWrapper{
    
    var firmwareUpgradeManager: FirmwareUpgradeManager?
    var imageData: Data?
    
    /* ---------------------------------------------------------------------------------------*/
    
    func upgrade(result: @escaping FlutterResult) -> Void{
        
        guard let data = self.imageData else {
            self.statusStreamHandler.send(Status.failed.rawValue)
            return
        }
        
        do {
            self.firmwareUpgradeManager?.mode = .confirmOnly
            try self.firmwareUpgradeManager?.start(data: data)
            self.statusStreamHandler.send(Status.inProgress.rawValue)
            
        } catch {
            self.statusStreamHandler.send(Status.failed.rawValue)
        }
    }
    
    func pauseUpgrade(result: @escaping FlutterResult) -> Void{
        self.firmwareUpgradeManager?.pause()
    }
    
    func resumeUpgrade(result: @escaping FlutterResult) -> Void{
        self.firmwareUpgradeManager?.resume()
    }
    
    func cancelUpgrade(result: @escaping FlutterResult) -> Void{
        self.firmwareUpgradeManager?.cancel()
    }
}


extension FirmwareUpgradeManagerWrapper: FirmwareUpgradeDelegate{
    
    public func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        self.progressStreamHandler.send(Float(bytesSent) / Float(imageSize))
    }
    
    public func upgradeDidStart(controller: FirmwareUpgradeController) {
        self.statusStreamHandler.send(Status.inProgress.rawValue)
    }
    
    public func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
//        var status: String
//        switch newState {
//        case .validate:
//            status = "Validating"
//        case .upload:
//            status = "Uploading"
//        case .test:
//            status = "Testing"
//        case .confirm:
//            status = "Confirming"
//        case .reset:
//            status = "Reseting"
//        case .success:
//            status = "Success"
//        default:
//            status = ""
//        }
//        self.statusStreamHandler.send(status)
        
    }
    
    public func upgradeDidComplete() {
        self.statusStreamHandler.send(Status.success.rawValue)
        self.imageData = nil
    }
    
    public func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        self.statusStreamHandler.send(Status.failed.rawValue)
        self.progressStreamHandler.send(0.0)
        
    }
    
    public func upgradeDidCancel(state: FirmwareUpgradeState) {
        self.statusStreamHandler.send(Status.canceled.rawValue)
        self.progressStreamHandler.send(0.0)
    }
    
}
