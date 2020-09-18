package com.korantom.flutter_mcumgr;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.content.Context;
import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.UUID;

import io.flutter.plugin.common.MethodChannel;
import no.nordicsemi.android.ble.BleManager;
import no.nordicsemi.android.ble.ReadRequest;
import no.nordicsemi.android.ble.WriteRequest;
import no.nordicsemi.android.ble.callback.DataReceivedCallback;
import no.nordicsemi.android.ble.callback.DataSentCallback;
import no.nordicsemi.android.ble.callback.FailCallback;
import no.nordicsemi.android.ble.callback.InvalidRequestCallback;
import no.nordicsemi.android.ble.callback.SuccessCallback;
import no.nordicsemi.android.ble.data.Data;

public class SettingsManager extends BleManager {

    public SettingsManager(@NonNull Context context) {
        super(context);
    }

    /* ------------------------------------------------------------------------------------------ */

    private final static UUID SETTINGS_SERVICE_UUID = UUID.fromString("4153dc1d-1d21-4cd3-868b-18527460aa02");
    private final static UUID SETTINGS_CHARACTERISTIC_UUID = UUID.fromString("db2e7800-fb00-4e01-ae9e-001174007c00");

    private BluetoothGattCharacteristic settingsCharacteristic;

    /* ------------------------------------------------------------------------------------------ */

    @NonNull
    @Override
    protected BleManagerGattCallback getGattCallback() {
        return new SettingsManagerGattCallback();
    }

    private class SettingsManagerGattCallback extends BleManagerGattCallback {

        @Override
        protected void initialize() {
        }

        @Override
        public boolean isRequiredServiceSupported(@NonNull final BluetoothGatt gatt) {
            final BluetoothGattService service = gatt.getService(SETTINGS_SERVICE_UUID);

            if (service == null) {
                System.out.println("Settings Service not found");
                return false;
            }

            System.out.println("Settings Service found");
            settingsCharacteristic = service.getCharacteristic(SETTINGS_CHARACTERISTIC_UUID);

            boolean writeRequest = false;
            boolean writeCommand = false;

            if (settingsCharacteristic != null) {
                final int characteristicProperties = settingsCharacteristic.getProperties();
                writeRequest = (characteristicProperties & BluetoothGattCharacteristic.PROPERTY_WRITE) > 0;
                writeCommand = (characteristicProperties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) > 0;

                if (writeRequest)
                    settingsCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
            }

            return settingsCharacteristic != null && (writeRequest || writeCommand);
        }

        @Override
        protected void onDeviceDisconnected() {
            settingsCharacteristic = null;
        }
    }

    public void send(final String text, @NonNull final MethodChannel.Result result) {

        if (settingsCharacteristic == null || TextUtils.isEmpty(text))
            return;

        final WriteRequest request = writeCharacteristic(settingsCharacteristic, text.getBytes());

        request.done(new SuccessCallback() {
            @Override
            public void onRequestCompleted(@NonNull BluetoothDevice device) {
                result.success(true);
            }
        });

        request.fail(new FailCallback() {
            @Override
            public void onRequestFailed(@NonNull BluetoothDevice device, int status) {
                result.error("WRITE_TO_CHARACTERISTIC_ERROR", "Failed to write value to characteristic", "status code: " + status);
            }
        });

        request.split();
        request.enqueue();

    }

    public void read(@NonNull final MethodChannel.Result result) {

        if (settingsCharacteristic == null)
            return;

        final ReadRequest request = readCharacteristic(settingsCharacteristic).with(new DataReceivedCallback() {
            @Override
            public void onDataReceived(@NonNull BluetoothDevice device, @NonNull Data data) {
                result.success(data.getStringValue(0));
            }
        });

        request.enqueue();
    }
}
