package com.korantom.flutter_mcumgr;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;

import androidx.annotation.NonNull;


import com.korantom.flutter_mcumgr.device_services.BleServiceManager;
import com.korantom.flutter_mcumgr.device_services.GattService;
import com.korantom.flutter_mcumgr.device_services.SettingsServiceManager;
import com.korantom.flutter_mcumgr.device_services.UARTServiceManager;

import org.apache.commons.io.FileUtils;

import java.io.File;
import java.util.Arrays;
import java.util.HashMap;


import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.runtime.mcumgr.McuMgrCallback;
import io.runtime.mcumgr.ble.McuMgrBleTransport;
import io.runtime.mcumgr.dfu.FirmwareUpgradeManager;
import io.runtime.mcumgr.exception.McuMgrException;
import io.runtime.mcumgr.managers.DefaultManager;
import io.runtime.mcumgr.managers.FsManager;
import io.runtime.mcumgr.managers.ImageManager;
import io.runtime.mcumgr.response.McuMgrResponse;
import io.runtime.mcumgr.response.dflt.McuMgrEchoResponse;
import no.nordicsemi.android.ble.callback.FailCallback;
import no.nordicsemi.android.ble.callback.SuccessCallback;

/**
 * FlutterMcumgrPlugin
 */

public class FlutterMcumgrPlugin implements FlutterPlugin, MethodCallHandler {
    final static String NAMESPACE = "korantom.flutter_mcumgr";

    private Context context;

    private MethodChannel methodChannel;

    private McuMgrBleTransport transport;

    private ImageManagerWrapper imageManager;
    private FirmwareUpgradeManagerWrapper firmwareUpgradeManager;
    private FileSystemManagerWrapper fsManager;
    private UARTServiceManager uartManager;
    private SettingsServiceManager settingsManager;



    /* ------------------------------------------------------------------------------------------ */

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        System.out.println("flutterPluginBinding");
        this.context = flutterPluginBinding.getApplicationContext();

        this.methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), String.format("%s/method", NAMESPACE));

        this.imageManager = new ImageManagerWrapper(String.format("%s/event/upload", NAMESPACE), flutterPluginBinding);
        this.firmwareUpgradeManager = new FirmwareUpgradeManagerWrapper(String.format("%s/event/upgrade", NAMESPACE), flutterPluginBinding);
        this.fsManager = new FileSystemManagerWrapper(String.format("%s/event/file", NAMESPACE), flutterPluginBinding);
        this.uartManager = new UARTServiceManager();
        this.settingsManager = new SettingsServiceManager();

        this.methodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
    }

    /* ---------------------------------------------------------------------------------------*/

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects
    public static void registerWith(Registrar registrar) {
        final FlutterMcumgrPlugin plugin = new FlutterMcumgrPlugin();
        System.out.println("registerWith");
        plugin.context = registrar.activeContext();

        plugin.methodChannel = new MethodChannel(registrar.messenger(), String.format("%s/method", NAMESPACE));

        plugin.imageManager = new ImageManagerWrapper(String.format("%s/event/upload", NAMESPACE), registrar);
        plugin.firmwareUpgradeManager = new FirmwareUpgradeManagerWrapper(String.format("%s/event/upgrade", NAMESPACE), registrar);
        plugin.fsManager = new FileSystemManagerWrapper(String.format("%s/event/file", NAMESPACE), registrar);
        plugin.uartManager = new UARTServiceManager();
        plugin.settingsManager = new SettingsServiceManager();


        plugin.methodChannel.setMethodCallHandler(plugin);
    }

    /* ---------------------------------------------------------------------------------------*/

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        HashMap<String, Object> arguments;
        try {
            arguments = (HashMap<String, Object>) call.arguments;
        } catch (Exception e) {
            arguments = new HashMap<String, Object>();
        }

        System.out.println(call.method);
        System.out.println(arguments);

        switch (call.method) {
            case "echo":
                _echo((String) arguments.get("macAddress"), (String) arguments.get("message"), result);
                break;
            case "connect":
                _connect((String) arguments.get("macAddress"), result);
                break;
            case "read":
                imageManager._read(result);
                break;
            case "load":
                _load((String) arguments.get("filePath"), result);
                break;
            case "upload":
                imageManager._upload(result);
                break;
            case "pauseUpload":
                imageManager._pauseUpload(result);
                break;
            case "resumeUpload":
                imageManager._resumeUpload(result);
                break;
            case "cancelUpload":
                imageManager._cancelUpload(result);
                break;
            case "upgrade":
                firmwareUpgradeManager._upgrade(result);
                break;
            case "pauseUpgrade":
                firmwareUpgradeManager._pauseUpgrade(result);
                break;
            case "resumeUpgrade":
                firmwareUpgradeManager._resumeUpgrade(result);
                break;
            case "cancelUpgrade":
                firmwareUpgradeManager._cancelUpgrade(result);
                break;
            case "confirm":
                imageManager._confirm((byte[]) arguments.get("hash"), result);
                break;
            case "erase":
                imageManager._erase(result);
                break;
            case "reset":
                _reset(result);
                break;
            case "readFile":
                fsManager._readFile((String) arguments.get("filePath"), result);
                break;
            case "sendTextCommand":
                uartManager.send((String) arguments.get("text"), result);
                break;
            case "pauseTransfer":
                fsManager._pauseTransfer(result);
                break;
            case "resumeTransfer":
                fsManager._resumeTransfer(result);
                break;
            case "cancelTransfer":
                fsManager._cancelTransfer(result);
                break;
            case "readSettings":
                settingsManager.readSettings(result);
                break;
            case "changeSettings":
                settingsManager.changeSettings((String) arguments.get("settings"), result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    /* ---------------------------------------------------------------------------------------*/

    public void _echo(String macAddress, String message, @NonNull final Result result) {
        BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothDevice device = bluetoothManager.getAdapter().getRemoteDevice(macAddress);
        McuMgrBleTransport transporter = new McuMgrBleTransport(context, device);
        DefaultManager manager = new DefaultManager(transporter);

        manager.echo(message, new McuMgrCallback<McuMgrEchoResponse>() {
            @Override
            public void onResponse(@NonNull final McuMgrEchoResponse response) {
                result.success(response.r);
            }

            @Override
            public void onError(@NonNull final McuMgrException error) {
                result.error("DEVICE_ECHO_ERROR", "Failed to receive message from device", error.getLocalizedMessage());
            }
        });
    }

    /* ---------------------------------------------------------------------------------------*/

    public void _connect(String macAddress, @NonNull final Result result) {
        BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothDevice device = bluetoothManager.getAdapter().getRemoteDevice(macAddress);
        this.transport = new McuMgrBleTransport(context, device);
        this.imageManager.setImageManager(new ImageManager(this.transport));
        this.firmwareUpgradeManager.setFirmwareUpgradeManager(new FirmwareUpgradeManager(this.transport));
        this.fsManager.setFsManager(new FsManager(this.transport));


        final BleServiceManager bleServiceManager = new BleServiceManager(context, Arrays.<GattService>asList(this.uartManager, this.settingsManager));

        bleServiceManager.connect(device).timeout(100000)
                .retry(6, 100)
                .done(new SuccessCallback() {
                    @Override
                    public void onRequestCompleted(@NonNull BluetoothDevice device) {
                        System.out.println("Device initiated");
                        System.out.println(device);
                        result.success(true);
                    }
                }).fail(new FailCallback() {
            @Override
            public void onRequestFailed(@NonNull BluetoothDevice device, int status) {
                System.out.println("Device failed " + status);
                result.success(false);
            }
        }).enqueue();

    }

    /* ---------------------------------------------------------------------------------------*/

    public void _load(String filePath, @NonNull final Result result) {
        File file = new File(filePath);
        byte[] imageData;
        try {
            imageData = FileUtils.readFileToByteArray(file);
            this.imageManager.setImageData(imageData);
            this.firmwareUpgradeManager.setImageData(imageData);
            result.success(true);
        } catch (Exception e) {
            imageData = null;
            result.error("LOAD_FILE_ERROR", "Failed to load file", e.getLocalizedMessage());
        }
        // TODO: try McuImage()
    }

    /* ---------------------------------------------------------------------------------------*/

    public void _reset(@NonNull final Result result) {
        if (this.transport == null) return;
        final DefaultManager defaultManager = new DefaultManager(this.transport);
        defaultManager.reset(new McuMgrCallback<McuMgrResponse>() {
            @Override
            public void onResponse(@NonNull final McuMgrResponse response) {
            }

            @Override
            public void onError(@NonNull final McuMgrException error) {
            }
        });

    }

    /* ---------------------------------------------------------------------------------------*/
}
