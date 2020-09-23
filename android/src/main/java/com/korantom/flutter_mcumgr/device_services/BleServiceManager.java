package com.korantom.flutter_mcumgr.device_services;

import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.List;

import no.nordicsemi.android.ble.BleManager;
import no.nordicsemi.android.ble.ReadRequest;
import no.nordicsemi.android.ble.ValueChangedCallback;
import no.nordicsemi.android.ble.WriteRequest;

public class BleServiceManager extends BleManager {

    final List<GattService> services;


    public BleServiceManager(@NonNull Context context, List<GattService> services) {
        super(context);
        this.services = services;

        for (GattService service : services) {
            service.setBleServiceManager(this);
        }
    }

    @NonNull
    @Override
    protected BleManagerGattCallback getGattCallback() {
        return new MyBleManagerGattCallback(this.services);
    }

    private class MyBleManagerGattCallback extends BleManagerGattCallback {
        final List<GattService> services;

        private MyBleManagerGattCallback(List<GattService> services) {
            this.services = services;
        }

        @Override
        protected void initialize() {
            requestMtu(256).enqueue();

            for (GattService service : services) {
                service.initialize();
            }
        }

        @Override
        protected boolean isRequiredServiceSupported(@NonNull BluetoothGatt gatt) {
            for (GattService service : services) {
                if (!service.isRequiredServiceSupported(gatt))
                    return false;
            }
            return true;
        }

        @Override
        protected void onDeviceDisconnected() {
            for (GattService service : services) {
                service.onDeviceDisconnected();
            }
        }
    }

    @Override
    @NonNull
    public WriteRequest writeCharacteristic(@Nullable final BluetoothGattCharacteristic characteristic,
                                            @Nullable final byte[] data) {
        return super.writeCharacteristic(characteristic, data);

    }

    @Override
    @NonNull
    public ReadRequest readCharacteristic(@Nullable final BluetoothGattCharacteristic characteristic) {
        return super.readCharacteristic(characteristic);
    }

    @Override
    @NonNull
    public ValueChangedCallback setNotificationCallback(@Nullable final BluetoothGattCharacteristic characteristic) {
        return super.setNotificationCallback(characteristic);
    }

    @Override
    @NonNull
    protected WriteRequest enableNotifications(
            @Nullable final BluetoothGattCharacteristic characteristic) {
        return super.enableNotifications(characteristic);
    }
}