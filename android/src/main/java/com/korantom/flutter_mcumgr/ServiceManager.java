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
import no.nordicsemi.android.ble.callback.SuccessCallback;
import no.nordicsemi.android.ble.data.Data;


/// Temporary solution
public class ServiceManager extends BleManager {

    private final static UUID UART_SERVICE_UUID = UUID.fromString("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
    private final static UUID UART_RX_CHARACTERISTIC_UUID = UUID.fromString("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
    private final static UUID UART_TX_CHARACTERISTIC_UUID = UUID.fromString("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");

    private BluetoothGattCharacteristic rxCharacteristic, txCharacteristic;

    private OnFinishCallback onDataReceived;

    // ------------------------------------------------------------------------------------------ //

    private final static UUID SETTINGS_SERVICE_UUID = UUID.fromString("4153dc1d-1d21-4cd3-868b-18527460aa02");
    private final static UUID SETTINGS_CHARACTERISTIC_UUID = UUID.fromString("db2e7800-fb00-4e01-ae9e-001174007c00");

    private BluetoothGattCharacteristic settingsCharacteristic;


    public ServiceManager(@NonNull Context context) {
        super(context);
    }

    @NonNull
    @Override
    protected BleManagerGattCallback getGattCallback() {
        return new ServiceManagerGattCallback();
    }

    private class ServiceManagerGattCallback extends BleManagerGattCallback {

        @Override
        protected void initialize() {
            setNotificationCallback(txCharacteristic).with(
                    new DataReceivedCallback() {
                        @Override
                        public void onDataReceived(@NonNull BluetoothDevice device, @NonNull Data data) {
                            final String text = data.getStringValue(0);
                            System.out.println("\"" + text + "\" received");
                            if (onDataReceived != null) onDataReceived.successOnMain(text);
                            onDataReceived = null;
                        }
                    });
            requestMtu(256);
            enableNotifications(txCharacteristic).enqueue();

        }

        @Override
        protected boolean isRequiredServiceSupported(@NonNull BluetoothGatt gatt) {

            final BluetoothGattService uartService = gatt.getService(UART_SERVICE_UUID);
            final BluetoothGattService settingsService = gatt.getService(SETTINGS_SERVICE_UUID);

            if (uartService == null || settingsService == null) {
                System.out.println("Service not found");
                return false;
            }

            rxCharacteristic = uartService.getCharacteristic(UART_RX_CHARACTERISTIC_UUID);
            txCharacteristic = uartService.getCharacteristic(UART_TX_CHARACTERISTIC_UUID);
            settingsCharacteristic = settingsService.getCharacteristic(SETTINGS_CHARACTERISTIC_UUID);


            boolean writeRequest = false;
            boolean writeCommand = false;

            if (rxCharacteristic != null) {
                final int rxProperties = rxCharacteristic.getProperties();
                writeRequest = (rxProperties & BluetoothGattCharacteristic.PROPERTY_WRITE) > 0;
                writeCommand = (rxProperties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) > 0;

                if (writeRequest)
                    rxCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
            }


            writeRequest = false;
            writeCommand = false;

            if (settingsCharacteristic != null) {
                final int characteristicProperties = settingsCharacteristic.getProperties();
                writeRequest = (characteristicProperties & BluetoothGattCharacteristic.PROPERTY_WRITE) > 0;
                writeCommand = (characteristicProperties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) > 0;

                if (writeRequest)
                    settingsCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
            }

            return settingsCharacteristic != null && rxCharacteristic != null;
        }

        @Override
        protected void onDeviceDisconnected() {
            rxCharacteristic = null;
            txCharacteristic = null;
            settingsCharacteristic = null;
        }
    }


    public void readSettings(@NonNull final MethodChannel.Result result) {

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

    public void changeSettings(final String text, @NonNull final MethodChannel.Result result) {

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

    public void sendUART(final String text, @NonNull final MethodChannel.Result result) {

        if (rxCharacteristic == null || onDataReceived != null)
            return;

        onDataReceived = new OnFinishCallback() {
            @Override
            public void success(Object message) {
                result.success(message);
            }

            @Override
            public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
                result.error(errorCode, errorMessage, errorDetails);
            }
        };

        if (!TextUtils.isEmpty(text)) {
            final WriteRequest request = writeCharacteristic(rxCharacteristic, text.getBytes())
                    .with(new DataSentCallback() {
                        @Override
                        public void onDataSent(@NonNull BluetoothDevice device, @NonNull Data data) {
                            System.out.println("\"" + data.getStringValue(0) + "\" sent");
                        }
                    });

            request.split();
            request.enqueue();
        }
    }
}
