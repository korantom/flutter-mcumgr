import Flutter
import UIKit
import McuManager
import CoreBluetooth
import os.log

public class SwiftFlutterMcumgrPlugin: NSObject, FlutterPlugin {
    
    static let NAMESPACE: String = "korantom.flutter_mcumgr"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let methodChannel = FlutterMethodChannel(name: "\(NAMESPACE)/method", binaryMessenger: registrar.messenger())
        
        
        let imageManagerWrapper = ImageManagerWrapper(name: "\(NAMESPACE)/event/upload", registrar: registrar)
        let firmwareUpgradeManagerWrapper = FirmwareUpgradeManagerWrapper(name: "\(NAMESPACE)/event/upgrade", registrar: registrar)
        let fileSystemManagerWrapper = FileSystemManagerWrapper(name: "\(NAMESPACE)/event/file", registrar: registrar)
        
        let instance = SwiftFlutterMcumgrPlugin(imageManager: imageManagerWrapper,
                                                firmwareUpgradeManager: firmwareUpgradeManagerWrapper,
                                                fileSystemManager: fileSystemManagerWrapper)
        
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        
    }
    
    private var centralManager: CBCentralManager
    
    private var uuid: UUID? {
        didSet {
            if let uuid = self.uuid {
                self.transporter = McuMgrBleTransport(uuid)
                self.uartManager.bluetoothPeripheral = self.centralManager.retrievePeripherals(withIdentifiers: [uuid]).first
            }
        }
    }
    
    private var transporter: McuMgrBleTransport! {
        didSet {
            self.imageManager.imageManager = ImageManager(transporter: transporter)
            self.firmwareUpgradeManager.firmwareUpgradeManager = FirmwareUpgradeManager(transporter: transporter, delegate: self.firmwareUpgradeManager)
            self.firmwareUpgradeManager.firmwareUpgradeManager!.estimatedSwapTime = 10.0
            self.fileSystemManager.fileSystemManager = FileSystemManager(transporter: transporter)
        }
    }
    
    
    private let imageManager: ImageManagerWrapper
    private let firmwareUpgradeManager: FirmwareUpgradeManagerWrapper
    private let fileSystemManager: FileSystemManagerWrapper
    private let uartManager: UARTManager
    
    init(imageManager: ImageManagerWrapper, firmwareUpgradeManager: FirmwareUpgradeManagerWrapper, fileSystemManager: FileSystemManagerWrapper) {
        
        self.centralManager = CBCentralManager()
        self.imageManager = imageManager
        self.firmwareUpgradeManager = firmwareUpgradeManager
        self.fileSystemManager = fileSystemManager
        self.uartManager = UARTManager()
        
        super.init()
        
        centralManager.delegate = self
        
    }
    
    /* ---------------------------------------------------------------------------------------*/
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        let arguements = call.arguments as? Dictionary<String, AnyObject> ?? Dictionary<String, AnyObject>()
        
        if call.method == "echo"{
            _echo(macAddr: arguements["macAddress"] as! String, message: arguements["message"] as! String, result: result)
            
        }else if call.method == "connect"{
            _connect(macAddr: arguements["macAddress"] as! String, result: result)
            
        }else if call.method == "read"{
            imageManager.read(result: result)
            
        }else if call.method == "load"{
            _load(filePath:  arguements["filePath"] as! String, result: result)
            
        }else if call.method == "upload"{
            imageManager.upload(result: result)
            
        }else if call.method == "pauseUpload"{
            imageManager.pauseUpload(result: result)
            
        }else if call.method == "resumeUpload"{
            imageManager.resumeUpload(result: result)
            
        }else if call.method == "cancelUpload"{
            imageManager.cancelUpload(result: result)
            
        }else if call.method == "upgrade"{
            firmwareUpgradeManager.upgrade(result: result)
            
        }else if call.method == "pauseUpgrade"{
            firmwareUpgradeManager.pauseUpgrade(result: result)
            
        }else if call.method == "resumeUpgrade"{
            firmwareUpgradeManager.resumeUpgrade(result: result)
            
        }else if call.method == "cancelUpgrade"{
            firmwareUpgradeManager.cancelUpgrade(result: result)
            
        }else if call.method == "confirm"{
            imageManager.confirm(hash: [UInt8]((arguements["hash"] as! FlutterStandardTypedData).data),
                                 result: result)
            
        }else if call.method == "erase"{
            imageManager.erase(result: result)
            
        }else if call.method == "reset"{
            _reset(result: result)
            
        }else if call.method == "readFile"{
            fileSystemManager.readFile(filePath:  arguements["filePath"] as! String, result: result)
            
        }else if call.method == "sendTextCommand"{
            uartManager.send(command: TextCommand(text: arguements["text"] as! String), result: result)
   
        }else if call.method == "pauseTransfer"{
                   fileSystemManager.pauseTransfer(result: result)
              
        }else if call.method == "resumeTransfer"{
                   fileSystemManager.resumeTransfer(result: result)
              
        }else if call.method == "cancelTransfer"{
                   fileSystemManager.cancelTransfer(result: result)
              
        }else{
            result(FlutterMethodNotImplemented)
            
        }
        
    }
    
    /* ---------------------------------------------------------------------------------------*/
    
    func _echo(macAddr: String, message: String, result: @escaping FlutterResult) -> Void{
        
        guard let uuid = UUID(uuidString: macAddr) else {
            result(FlutterError(code: "DEVICE_ADDRESS_ERROR",
                                message: "Device address conversion to uuid failed",
                                details: "Device uuid \(macAddr) convert to uuid failed"))
            return
        }
        
        let transporter = McuMgrBleTransport(uuid)
        let defaultManager = DefaultManager(transporter: transporter)
        
        defaultManager.echo(message) { (response, error) in
            if let response = response {
                result(response.response ?? "No reply")
            }
            if let error = error {
                result(FlutterError(code: "DEVICE_ECHO_ERROR",
                                    message: "Failed to receive message from device",
                                    details: "\(error.localizedDescription)"))
            }
        }
    }
    
    /* ---------------------------------------------------------------------------------------*/
    
    func _connect(macAddr: String, result: @escaping FlutterResult){
        
        guard let uuid = UUID(uuidString: macAddr) else {
            result(FlutterError(code: "DEVICE_ADDRESS_ERROR",
                                message: "Device address conversion to uuid failed",
                                details: "Device uuid \(macAddr) convert to uuid failed"))
            return
        }
        
        self.uuid = uuid
        
        guard let bluetoothPeripheral = uartManager.bluetoothPeripheral else {
            result(false)
            return
        }
        
        centralManager.connect(bluetoothPeripheral, options: nil)
        
        result(true)
    }
    
    /* ---------------------------------------------------------------------------------------*/
    
    func _load(filePath: String, result: @escaping FlutterResult) -> Void{
        
        let url = NSURL.fileURL(withPath: filePath)
        
        guard let data = dataFrom(url: url) else {
            result(FlutterError(code: "FILE_LOAD_ERROR",
                                message: "Failed to load file",
                                details: "Failed to load file from path \(filePath)"))
            return
        }
        
        do {
            let image = try McuMgrImage(data: data)
            result(["fileName": url.lastPathComponent,
                    "dataSize": String(data.count),
                    "hash": [UInt8] (image.hash),
                    "hashStr": image.hash.hexString,
            ])
            
            self.imageManager.imageData = data
            self.firmwareUpgradeManager.imageData = data
            self.fileSystemManager.imageData = data
            
        } catch {
            result(FlutterError(code: "IMAGE_LOAD_ERROR",
                                message: "Failed read data as Image",
                                details: ""))
        }
        
    }
    
    /* ---------------------------------------------------------------------------------------*/
    
    func _reset(result: @escaping FlutterResult) -> Void{
        let defaultManager = DefaultManager(transporter: self.transporter)
        defaultManager.reset { (response, error) in
        }
    }
        
    /* ---------------------------------------------------------------------------------------*/
    
    private func dataFrom(url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            log("Error reading file: \(error)", ofCategory: .default, atLevel: .error)
            return nil
        }
    }
}


extension SwiftFlutterMcumgrPlugin: CBCentralManagerDelegate{
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log("\(central.state)", ofCategory: .default, atLevel: .verbose)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("[Callback] Central Manager did connect peripheral", ofCategory: .default, atLevel: .verbose)
        if let name = peripheral.name {
            log("Connected to: \(name)", ofCategory: .default, atLevel: .verbose)
        } else {
            log("Connected to device", ofCategory: .default, atLevel: .verbose)
        }
        
        log("Discovering services...", ofCategory: .default, atLevel: .verbose)
        log("peripheral.discoverServices([\(self.uartManager.UARTServiceUUID.uuidString)])", ofCategory: .default, atLevel: .verbose)
        peripheral.discoverServices([self.uartManager.UARTServiceUUID])
    }
}

extension SwiftFlutterMcumgrPlugin: McuMgrLogDelegate {
    
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

extension McuMgrLogLevel {
    
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

extension McuMgrLogCategory {
    
    @available(iOS 10.0, *)
    var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
    }
    
}

