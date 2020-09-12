package com.korantom.flutter_mcumgr;

import android.os.Handler;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.runtime.mcumgr.dfu.FirmwareUpgradeCallback;
import io.runtime.mcumgr.dfu.FirmwareUpgradeController;
import io.runtime.mcumgr.dfu.FirmwareUpgradeManager;
import io.runtime.mcumgr.exception.McuMgrException;

public class FirmwareUpgradeManagerWrapper extends ManagerWrapper implements FirmwareUpgradeCallback {

    private FirmwareUpgradeManager firmwareUpgradeManager;
    private byte[] imageData;


    public FirmwareUpgradeManagerWrapper(String name, @NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        super(name, flutterPluginBinding);
    }

    public FirmwareUpgradeManagerWrapper(String name, PluginRegistry.Registrar registrar) {
        super(name, registrar);
    }

    /* --------------------------------------------------------------------------------------- */

    public FirmwareUpgradeManager getFirmwareUpgradeManager() {
        return firmwareUpgradeManager;
    }

    public void setFirmwareUpgradeManager(FirmwareUpgradeManager firmwareUpgradeManager) {
        this.firmwareUpgradeManager = firmwareUpgradeManager;
    }

    public byte[] getImageData() {
        return imageData;
    }

    public void setImageData(byte[] imageData) {
        this.imageData = imageData;
    }

    /* --------------------------------------------------------------------------------------- */
    public void _upgrade(@NonNull final MethodChannel.Result result) {
        if (this.firmwareUpgradeManager == null) return;

        if (this.imageData == null) {
            this.statusStreamHandler.send("File not loaded");
            return;
        }

        try {
            this.firmwareUpgradeManager.setFirmwareUpgradeCallback(this);
            this.firmwareUpgradeManager.start(this.imageData);
        } catch (final McuMgrException e) {

        }
    }

    public void _pauseUpgrade(@NonNull final MethodChannel.Result result) {
        if (this.firmwareUpgradeManager == null) return;
        this.firmwareUpgradeManager.pause();
    }

    public void _resumeUpgrade(@NonNull final MethodChannel.Result result) {
        if (this.firmwareUpgradeManager == null) return;
        this.firmwareUpgradeManager.resume();
    }

    public void _cancelUpgrade(@NonNull final MethodChannel.Result result) {
        if (this.firmwareUpgradeManager == null) return;
        this.firmwareUpgradeManager.cancel();
    }

    /* --------------------------------------------------------------------------------------- */

    @Override
    public void onUploadProgressChanged(int current, int total, long timestamp) {
        this.progressStreamHandler.send((double) current / total);
    }

    @Override
    public void onUpgradeStarted(FirmwareUpgradeController controller) {
        this.statusStreamHandler.send("Upgrade started");
    }

    @Override
    public void onStateChanged(FirmwareUpgradeManager.State prevState, FirmwareUpgradeManager.State newState) {
        switch (newState) {
            case VALIDATE:
                this.statusStreamHandler.send("Validating");
                break;
            case UPLOAD:
                this.statusStreamHandler.send("Uploading");
                break;
            case TEST:
                this.statusStreamHandler.send("Testing");
                break;
            case CONFIRM:
                this.statusStreamHandler.send("Confirming");
                break;
            case RESET:
                this.statusStreamHandler.send("Reseting");
                break;
            case SUCCESS:
                this.statusStreamHandler.send("Success");
                break;
            default:
                this.statusStreamHandler.send("_");
                break;
        }
    }

    @Override
    public void onUpgradeCompleted() {
        this.statusStreamHandler.send("Upgrade Completed");
        this.imageData = null;
        this.firmwareUpgradeManager = null;
    }

    @Override
    public void onUpgradeFailed(FirmwareUpgradeManager.State state, McuMgrException error) {
        this.statusStreamHandler.send("Upload Failed");
        this.progressStreamHandler.send(0.0);
        // TODO: result.error
    }

    @Override
    public void onUpgradeCanceled(FirmwareUpgradeManager.State state) {
        this.statusStreamHandler.send("Upload Canceled");
        this.progressStreamHandler.send(0.0);
    }

    /* --------------------------------------------------------------------------------------- */
}
