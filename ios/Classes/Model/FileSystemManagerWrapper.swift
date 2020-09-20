//
//  FileSystemManagerWrapper.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 06/09/2020.
//

import Foundation
import McuManager

class FileSystemManagerWrapper: ManagerWrapper{
    var fileSystemManager: FileSystemManager?
    var imageData: Data?
    private var onDownload: ((Any) -> Void)?
    
    func readFile(filePath: String, result: @escaping FlutterResult) -> Void{
        onDownload =  { (message) in
            result(message)
        }
        _ = self.fileSystemManager?.download(name: filePath, delegate: self)
    }
    
    func pauseTransfer(result: @escaping FlutterResult) -> Void{
        self.fileSystemManager?.pauseTransfer()
    }
    
    func resumeTransfer(result: @escaping FlutterResult) -> Void{
        self.fileSystemManager?.continueTransfer()
    }
    
    func cancelTransfer(result: @escaping FlutterResult) -> Void{
        self.fileSystemManager?.cancelTransfer()
    }
    
}


extension FileSystemManagerWrapper: FileDownloadDelegate{
    
    public func downloadProgressDidChange(bytesDownloaded: Int, fileSize: Int, timestamp: Date) {
        self.progressStreamHandler.send(Float(bytesDownloaded) / Float(fileSize))
    }
    
    public func downloadDidFail(with error: Error) {
        switch error as? FileTransferError {
        case .mcuMgrErrorCode(.unknown):
            self.statusStreamHandler.send("File not found")
        default:
            self.statusStreamHandler.send("\(error.localizedDescription)")
        }
        self.progressStreamHandler.send(0.0)
    }
    
    public func downloadDidCancel() {
        self.statusStreamHandler.send("Download Canceled")
        self.progressStreamHandler.send(0.0)
    }
    
    public func download(of name: String, didFinish data: Data) {
        self.statusStreamHandler.send("\(name) (\(data.count) bytes)")
        
        onDownload?(FlutterStandardTypedData(bytes: data))
        
        onDownload =  nil
    }
    
}
