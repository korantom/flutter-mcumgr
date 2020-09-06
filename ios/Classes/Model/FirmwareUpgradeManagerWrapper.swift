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
            self.statusStreamHandler.send("File not loaded")
            return
        }
        
        do {
            self.firmwareUpgradeManager?.mode = .confirmOnly
            try self.firmwareUpgradeManager?.start(data: data)
            self.statusStreamHandler.send("Upgrade Started")
            
        } catch {
            self.statusStreamHandler.send("Upgrade Not Started")
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
        self.statusStreamHandler.send("Upgrade Started")
    }
    
    public func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        var status: String
        switch newState {
        case .validate:
            status = "Validating"
        case .upload:
            status = "Uploading"
        case .test:
            status = "Testing"
        case .confirm:
            status = "Confirming"
        case .reset:
            status = "Reseting"
        case .success:
            status = "Success"
        default:
            status = ""
        }
        self.statusStreamHandler.send(status)
        
    }
    
    public func upgradeDidComplete() {
        self.statusStreamHandler.send("Upgrade Finished")
        self.imageData = nil
    }
    
    public func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        self.statusStreamHandler.send("\(error.localizedDescription)")
        self.progressStreamHandler.send(0.0)
        
    }
    
    public func upgradeDidCancel(state: FirmwareUpgradeState) {
        self.statusStreamHandler.send("Upgrade Canceled")
        self.progressStreamHandler.send(0.0)
    }
    
}
