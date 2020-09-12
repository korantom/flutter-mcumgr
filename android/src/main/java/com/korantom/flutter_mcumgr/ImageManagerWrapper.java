package com.korantom.flutter_mcumgr;

import android.os.Handler;

import androidx.annotation.NonNull;

import com.google.gson.Gson;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.runtime.mcumgr.McuMgrCallback;
import io.runtime.mcumgr.exception.McuMgrException;
import io.runtime.mcumgr.managers.ImageManager;
import io.runtime.mcumgr.response.McuMgrResponse;
import io.runtime.mcumgr.response.img.McuMgrImageStateResponse;
import io.runtime.mcumgr.transfer.TransferController;
import io.runtime.mcumgr.transfer.UploadCallback;

public class ImageManagerWrapper extends ManagerWrapper implements UploadCallback {

    private ImageManager imageManager;
    private TransferController transferController;
    private byte[] imageData;


    public ImageManagerWrapper(String name, @NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        super(name, flutterPluginBinding);
    }

    public ImageManagerWrapper(String name, PluginRegistry.Registrar registrar) {
        super(name, registrar);
    }

    /* ------------------------------------------------------------------------------------------ */

    public ImageManager getImageManager() {
        return imageManager;
    }

    public void setImageManager(ImageManager imageManager) {
        this.imageManager = imageManager;
    }

    public byte[] getImageData() {
        return imageData;
    }

    public void setImageData(byte[] imageData) {
        this.imageData = imageData;
    }

    /* ------------------------------------------------------------------------------------------ */

    public void _read(@NonNull final MethodChannel.Result result) {

        if (this.imageManager == null) return;

        this.imageManager.list(new McuMgrCallback<McuMgrImageStateResponse>() {
            @Override
            public void onResponse(@NonNull final McuMgrImageStateResponse response) {
                if (response.images == null || response.images.length < 1) return;

                List<FirmwareImage> firmwareImages = new ArrayList<FirmwareImage>();
                for (McuMgrImageStateResponse.ImageSlot image : response.images) {
                    firmwareImages.add(new FirmwareImage(image));
                }
                Gson gson = new Gson();
                String json = gson.toJson(firmwareImages);
                result.success(json);
            }

            @Override
            public void onError(@NonNull final McuMgrException error) {
                result.error("DEVICE_IMAGE_LIST_ERROR", "Failed to read images on device", error.getLocalizedMessage());
            }
        });
    }

    /* ------------------------------------------------------------------------------------------ */

    public void _upload(@NonNull final MethodChannel.Result result) {
        if (this.imageManager == null) return;

        if (this.imageData == null) {
            this.statusStreamHandler.send("File not loaded");
            return;
        }

        this.transferController = this.imageManager.imageUpload(this.imageData, this);
    }

    public void _pauseUpload(@NonNull final MethodChannel.Result result) {
        if (transferController == null) return;
        transferController.pause();
    }

    public void _resumeUpload(@NonNull final MethodChannel.Result result) {
        if (transferController == null) return;
        transferController.resume();
    }

    public void _cancelUpload(@NonNull final MethodChannel.Result result) {
        if (transferController == null) return;
        transferController.cancel();
    }

    /* ------------------------------------------------------------------------------------------ */

    @Override
    public void onUploadProgressChanged(int current, int total, long timestamp) {
        this.progressStreamHandler.send((double) current / total);
    }

    @Override
    public void onUploadFailed(@NotNull McuMgrException error) {
        this.statusStreamHandler.send("Upload Failed");
        this.progressStreamHandler.send(0.0);
        // TODO: result.error
    }

    @Override
    public void onUploadCanceled() {
        this.statusStreamHandler.send("Upload Canceled");
        this.progressStreamHandler.send(0.0);
    }

    @Override
    public void onUploadCompleted() {
        this.statusStreamHandler.send("Upload Finished");
        this.imageData = null;
        this.imageManager = null;
        this.transferController = null;
    }

    /* ------------------------------------------------------------------------------------------ */
    public void _confirm(byte[] hash, @NonNull final MethodChannel.Result result) {
        if (this.imageManager == null) return;

        this.imageManager.confirm(hash, new McuMgrCallback<McuMgrImageStateResponse>() {
            @Override
            public void onResponse(@NonNull final McuMgrImageStateResponse response) {
            }

            @Override
            public void onError(@NonNull final McuMgrException error) {
            }
        });
    }

    public void _erase(@NonNull final MethodChannel.Result result) {
        if (this.imageManager == null) return;
        this.imageManager.erase(new McuMgrCallback<McuMgrResponse>() {
            @Override
            public void onResponse(@NonNull final McuMgrResponse response) {
            }

            @Override
            public void onError(@NonNull final McuMgrException error) {
            }
        });
    }
    /* ------------------------------------------------------------------------------------------ */
}
