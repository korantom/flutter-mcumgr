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
    private var bluetoothPeripheral: CBPeripheral?
    private let serviceUUIDs: [CBUUID]
    private let serviceServiceManagers: [CBUUID : ServiceManager]
    private var characteristicServiceManagers: [CBUUID : ServiceManager]
    private let serviceManagers: [ServiceManager]
    private let targetCharacteristicCount: Int
    private var discoveredCharacteristicCount: Int = 0
    private var onConnected: ((Any) -> Void)?
    
    
    private var uuid: UUID? {
        didSet {
            if let uuid = self.uuid {
                self.transporter = McuMgrBleTransport(uuid)
                self.bluetoothPeripheral = self.centralManager.retrievePeripherals(withIdentifiers: [uuid]).first
                self.uartManager.bluetoothPeripheral = bluetoothPeripheral
                self.setttingsManager.bluetoothPeripheral = bluetoothPeripheral
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
    private let uartManager: UARTServiceManager
    private let setttingsManager: SettingsServiceManager
    
    init(imageManager: ImageManagerWrapper, firmwareUpgradeManager: FirmwareUpgradeManagerWrapper, fileSystemManager: FileSystemManagerWrapper) {
        
        self.centralManager = CBCentralManager()
        self.imageManager = imageManager
        self.firmwareUpgradeManager = firmwareUpgradeManager
        self.fileSystemManager = fileSystemManager
        self.uartManager = UARTServiceManager()
        self.setttingsManager = SettingsServiceManager()
        
        
        self.serviceUUIDs                   = [uartManager.serviceUUID,
                                               setttingsManager.serviceUUID]
        self.serviceServiceManagers         = [uartManager.serviceUUID:uartManager,
                                               setttingsManager.serviceUUID:setttingsManager]
        
        self.characteristicServiceManagers  = [:]
        
        self.serviceManagers = [uartManager, setttingsManager]
        
        self.targetCharacteristicCount = serviceManagers.map({ (serviceManager: ServiceManager) -> Int in
            return serviceManager.characteristicsUUIDs.count
        }).reduce(0, +)
            
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
            
        }else if call.method == "readSettings"{
            setttingsManager.read(result: result)
            
        }else if call.method == "changeSettings"{
            setttingsManager.send(setting: arguements["settings"] as! String, result: result)
            
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
        
        guard let bluetoothPeripheral = self.bluetoothPeripheral else {
            result(false)
            return
        }
        bluetoothPeripheral.delegate = self
        self.onConnected = { (reply) in result(reply)}
        centralManager.connect(bluetoothPeripheral, options: nil)
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
            log("Error reading file: \(error)", atLevel: .error)
            return nil
        }
    }
}


extension SwiftFlutterMcumgrPlugin: CBCentralManagerDelegate{
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log("\(central.state)", atLevel: .verbose)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("[Callback] Central Manager did connect peripheral", atLevel: .info)
        
        if let name = peripheral.name {
            log("Connected to: \(name)", atLevel: .verbose)
        } else {
            log("Connected to device", atLevel: .verbose)
        }
        
        log("Discovering services...", atLevel: .verbose)
        log("peripheral.discoverServices([\(self.serviceUUIDs)])", atLevel: .verbose)
        self.discoveredCharacteristicCount = 0
        peripheral.discoverServices(self.serviceUUIDs)
        
    }
}

extension SwiftFlutterMcumgrPlugin: CBPeripheralDelegate{
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard error == nil else {
            log("didDiscoverServices failed", atLevel: .info)
            log(error!.localizedDescription.description, atLevel: .verbose)
            return
        }
        
        log("didDiscoverServices", atLevel: .info)
        log("\(peripheral.services!.count) Services found", atLevel: .verbose)
        
        for aService: CBService in peripheral.services! {
            if self.serviceUUIDs.contains(aService.uuid) {
                log("peripheral.discoverCharacteristics(nil, for: \(aService.uuid.uuidString))", atLevel: .verbose)
                bluetoothPeripheral!.discoverCharacteristics(nil, for: aService)
            }
        }
        // TODO: cheeck all services discovered
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard error == nil else {
            log("didDiscoverCharacteristicsFor service \(service.uuid) failed", atLevel: .info)
            log(error!.localizedDescription.description, atLevel: .verbose)
            return
        }

        log("didDiscoverCharacteristicsFor service \(service.uuid)", atLevel: .info)
        
        guard var serviceManager = self.serviceManagers.first(where: { (ServiceManager) -> Bool in
            return ServiceManager.serviceUUID.isEqual(service.uuid)
        }) else {
            log("unkown service \(service)", atLevel: .info)
            return
        }

        
        for aCharacteristic : CBCharacteristic in service.characteristics! {
            serviceManager.characteristics[aCharacteristic.uuid] = aCharacteristic
            characteristicServiceManagers[aCharacteristic.uuid] = serviceManager
            self.discoveredCharacteristicCount += 1
            log( "Characteristic \(aCharacteristic.uuid) found", atLevel: .verbose)
        }
        
        for txUUID in serviceManager.TXCharacteristicsUUIDs {
            if let txCharacteristic = serviceManager.characteristics[txUUID]{
                bluetoothPeripheral!.setNotifyValue(true, for: txCharacteristic)
            }
        }
        if serviceManager.characteristics.count != serviceManager.characteristicsUUIDs.count{
            log( "\(service.uuid) service does not have all required characteristics.", atLevel: .verbose)
            self.onConnected?(FlutterError(code: "CONNECT_DEVICEE_ERROR",
                                           message: "Failed to find all neccesary characteristics",
                                           details: ""))
            self.onConnected = nil
        }
        
        if self.discoveredCharacteristicCount == self.targetCharacteristicCount{
            self.onConnected?(true)
            self.onConnected = nil
        }
        
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            log("Enabling notifications for \(characteristic.uuid) failed", atLevel: .verbose)
            log(error!.localizedDescription.description, atLevel: .verbose)
            return
        }
        
        if characteristic.isNotifying {
            log("Notifications enabled for characteristic: \(characteristic.uuid)", atLevel: .verbose)
        } else {
            log("Notifications disabled for characteristic: \(characteristic.uuid)", atLevel: .verbose)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {

        guard var serviceManager = self.characteristicServiceManagers[characteristic.uuid] else{
            //error should not happen
            return
        }
        
        guard error == nil else {
            log("didWriteValueFor characteristic \(characteristic.uuid) failed", atLevel: .info)
            log(error!.localizedDescription.description, atLevel: .verbose)
            
            serviceManager.onDidWriteToCharacteristic?(FlutterError(code: "WRITE_TO_CHARACTERISTIC_ERROR",
                                                                    message: "Failed to write value to characteristic",
                                                                    details: error!.localizedDescription.description))
            serviceManager.onDidWriteToCharacteristic = nil
            return
        }
        
        log("didWriteValueFor characteristic \(characteristic.uuid)", ofCategory: .settingsManager, atLevel: .info)
        serviceManager.onDidWriteToCharacteristic?(true)
        serviceManager.onDidWriteToCharacteristic = nil
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard var serviceManager = self.characteristicServiceManagers[characteristic.uuid] else{
            //error should not happen
            return
        }
        
        guard error == nil else {
            log( "didUpdateValueFor characteristic \(characteristic.uuid) failed", atLevel: .info)
            log( error!.localizedDescription.description, atLevel: .verbose)
            serviceManager.onDidUpdateValueForCharacterictic?(FlutterError(code: "UPDATE_VALUE_FOR_CHARACTERISTIC_ERROR",
                                                                           message: "Failed to update value for characteristic",
                                                                           details: error!.localizedDescription.description))
            serviceManager.onDidUpdateValueForCharacterictic = nil
            return
        }
        
        log( "didUpdateValueFor characteristic \(characteristic.uuid)", atLevel: .info)

        guard let bytesReceived = characteristic.value else {
            log( "Notification received from: \(characteristic.uuid.uuidString), with empty value", atLevel: .verbose)
            serviceManager.onDidUpdateValueForCharacterictic?("")
            serviceManager.onDidUpdateValueForCharacterictic = nil
            return
        }

        log( "Notification received from: \(characteristic.uuid.uuidString), with value: 0x\(bytesReceived.hexString)", atLevel: .verbose)
        
        if let validUTF8String = String(data: bytesReceived, encoding: .utf8) {
            log( "\"\(validUTF8String)\" received", atLevel: .verbose)
            serviceManager.onDidUpdateValueForCharacterictic?(validUTF8String)
        } else {
            log( "\"0x\(bytesReceived.hexString)\" received", atLevel: .verbose)
            serviceManager.onDidUpdateValueForCharacterictic?(bytesReceived.hexString)
        }
        serviceManager.onDidUpdateValueForCharacterictic = nil
    }
    
}

extension SwiftFlutterMcumgrPlugin: FlutterMcuMgrLogDelegate {
    
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
            os_log("%{public}@", log: FlutterMcuMgrLogCategory.flutterPlugin.log, type: level.type, msg)
        } else {
            NSLog("%@", msg)
        }
    }
    
}

