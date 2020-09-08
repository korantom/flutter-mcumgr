package com.korantom.flutter_mcumgr;

import android.os.Handler;
import android.os.Looper;

import io.flutter.plugin.common.EventChannel;

// TODO: rewrite, check OnFinishCallback getMainLooper

/**
 * StreamHandler
 *
 * handles communication (sending results) with flutter part of app, has to run on main thread
 */
class StreamHandler implements EventChannel.StreamHandler {
    private EventChannel.EventSink sink;
    private Handler mainHandler;

    StreamHandler() {
        this.mainHandler = new Handler(Looper.getMainLooper());
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.sink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        this.sink = null;
    }

    public void send(final Object message) {
        if (StreamHandler.this.sink == null) return;
        Runnable myRunnable = new Runnable() {
            @Override
            public void run() {
                sink.success(message);
            }
        };
        mainHandler.post(myRunnable);
    }
}
