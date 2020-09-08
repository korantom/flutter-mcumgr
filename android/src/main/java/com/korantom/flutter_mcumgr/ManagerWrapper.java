package com.korantom.flutter_mcumgr;

import android.os.Handler;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;


/**
 * ManagerWrapper
 *
 * provides status and progress communication channels
 */
public abstract class ManagerWrapper {
    protected EventChannel progressEventChannel;
    protected EventChannel statusEventChannel;

    protected StreamHandler progressStreamHandler;
    protected StreamHandler statusStreamHandler;

    public ManagerWrapper(String name, @NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding){
        this.progressEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), String.format("%s/progress", name));
        this.statusEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), String.format("%s/status", name));

        this.progressStreamHandler = new StreamHandler();
        this.statusStreamHandler = new StreamHandler();


        this.progressEventChannel.setStreamHandler(progressStreamHandler);
        this.statusEventChannel.setStreamHandler(statusStreamHandler);
    }
}
