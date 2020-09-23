package com.korantom.flutter_mcumgr;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.jetbrains.annotations.NotNull;

import java.io.UnsupportedEncodingException;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.runtime.mcumgr.exception.McuMgrException;
import io.runtime.mcumgr.managers.FsManager;
import io.runtime.mcumgr.transfer.DownloadCallback;
import io.runtime.mcumgr.transfer.TransferController;

public class FileSystemManagerWrapper extends ManagerWrapper implements DownloadCallback {

    private FsManager fsManager;
    private TransferController transferController;
    private OnFinishCallback onFinish;

    public FileSystemManagerWrapper(String name, @NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        super(name, flutterPluginBinding);
    }

    public FileSystemManagerWrapper(String name, PluginRegistry.Registrar registrar) {
        super(name, registrar);
    }

    /* --------------------------------------------------------------------------------------- */

    public FsManager getFsManager() {
        return fsManager;
    }

    public void setFsManager(FsManager fsManager) {
        this.fsManager = fsManager;
    }

    /* --------------------------------------------------------------------------------------- */

    public void _readFile(String filePath, @NonNull final MethodChannel.Result result) {
        if (this.fsManager == null) return;

        onFinish = new OnFinishCallback() {
            @Override
            public void success(Object message) {
                result.success(message);
            }

            @Override
            public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
                result.error(errorCode, errorMessage, errorDetails);
            }
        };
        this.transferController = this.fsManager.fileDownload(filePath, this);
        this.statusStreamHandler.send("Download Started");
    }

    public void _pauseTransfer(@NonNull final MethodChannel.Result result) {
        if (transferController == null) return;
        transferController.pause();
    }

    public void _resumeTransfer(@NonNull final MethodChannel.Result result) {
        if (transferController == null) return;
        transferController.resume();
    }

    public void _cancelTransfer(@NonNull final MethodChannel.Result result) {
        if (transferController == null) return;
        transferController.cancel();
    }

    /* --------------------------------------------------------------------------------------- */


    @Override
    public void onDownloadProgressChanged(int current, int total, long timestamp) {
        this.progressStreamHandler.send((double) current / total);
    }

    @Override
    public void onDownloadFailed(@NotNull McuMgrException error) {
        this.statusStreamHandler.send("Download Failed");
        this.progressStreamHandler.send(0.0);
        // TODO: result.error
    }

    @Override
    public void onDownloadCanceled() {
        this.statusStreamHandler.send("Download Canceled");
        this.progressStreamHandler.send(0.0);
    }

    @Override
    public void onDownloadCompleted(@NotNull byte[] data) {
        this.statusStreamHandler.send(data.length + "bytes");
        onFinish.successOnMain(data);
        onFinish = null;
    }

    /* --------------------------------------------------------------------------------------- */
}
