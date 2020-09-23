package com.korantom.flutter_mcumgr;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.Nullable;

/**
 * OnFinishCallback
 *
 * Communication with Flutter part of app has to be done on main thread, ...
 * */
public abstract class OnFinishCallback {

    public void success(@Nullable Object result) {
    }

    void doSomething() {
    }

    public void successOnMain(@Nullable final Object result) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                success(result);
            }
        });
    }

    public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
    }

    public void errorOnMain(final String errorCode, @Nullable final String errorMessage, @Nullable final Object errorDetails) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                error(errorCode, errorMessage, errorDetails);
            }
        });
    }
}