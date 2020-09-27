//
//  ImageManagerWrapper.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 06/09/2020.
//

import Foundation
import McuManager

class ImageManagerWrapper: ManagerWrapper{
    
    var imageManager: ImageManager?
    var imageData: Data?
    
    /* ---------------------------------------------------------------------------------------*/
    
    func read(result: @escaping FlutterResult) -> Void{
        guard let imageManager = self.imageManager else {
            // TODO: log
            return
        }
        
        imageManager.list { (response, error) in
            if let response = response {
                if response.isSuccess(), let images = response.images {
                    
                    let encoder = JSONEncoder()
                    let firmwareImages = images.map({ (image) -> FirmwareImage in
                        return FirmwareImage(image: image)
                    })
                    
                    let data = try? encoder.encode(firmwareImages)
                    result((String(data: data ?? Data(), encoding: .utf8)!) )
                    
                } else {
                    result(FlutterError(code: "DEVICE_IMAGE_LIST_ERROR",
                                        message: "Failed to read images on device",
                                        details: ""))
                }
            }
            
            if let error = error {
                result(FlutterError(code: "DEVICE_IMAGE_LIST_ERROR",
                                    message: "Failed to read images on device",
                                    details: "\(error.localizedDescription)"))
            }
        }
    }
    
    /* ---------------------------------------------------------------------------------------*/
    
    func upload(result: @escaping FlutterResult) -> Void{
        
        guard let data = self.imageData else {
            self.statusStreamHandler.send(Status.failed.rawValue)
            return
        }
        
        if self.imageManager!.upload(data: data, delegate: self){
            self.statusStreamHandler.send(Status.inProgress.rawValue)
        }else{
            self.statusStreamHandler.send(Status.failed.rawValue)
        }
    }
    
    func pauseUpload(result: @escaping FlutterResult) -> Void{
        self.imageManager?.pauseUpload()
    }
    
    func resumeUpload(result: @escaping FlutterResult) -> Void{
        self.imageManager?.continueUpload()
    }
    
    func cancelUpload(result: @escaping FlutterResult) -> Void{
        self.imageManager?.cancelUpload()
    }
    
    /* ---------------------------------------------------------------------------------------*/
    
    func confirm(hash: [UInt8], result: @escaping FlutterResult) -> Void{
        self.imageManager?.confirm(hash: hash) { (response, error) in
        }
    }
    
    func erase(result: @escaping FlutterResult) -> Void{
        self.imageManager?.erase { (response, error) in
        }
    }
    
}


extension ImageManagerWrapper: ImageUploadDelegate {
    
    public func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        self.progressStreamHandler.send(Float(bytesSent) / Float(imageSize))
    }
    
    public func uploadDidFail(with error: Error) {
        self.statusStreamHandler.send(Status.failed.rawValue)
        self.progressStreamHandler.send(0.0)
    }
    
    public func uploadDidCancel() {
        self.statusStreamHandler.send(Status.canceled.rawValue)
        self.progressStreamHandler.send(0.0)
    }
    
    public func uploadDidFinish() {
        self.statusStreamHandler.send(Status.success.rawValue)
        self.imageData = nil
    }
}
