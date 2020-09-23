package com.korantom.flutter_mcumgr.device_services;

import android.bluetooth.BluetoothGatt;

import androidx.annotation.NonNull;

public interface GattService {

    public void initialize();

    public boolean isRequiredServiceSupported(@NonNull final BluetoothGatt gatt);

    public void onDeviceDisconnected();

    public void setBleServiceManager(BleServiceManager adapter);
}