package com.korantom.flutter_mcumgr.device_services;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.korantom.flutter_mcumgr.OnFinishCallback;

import java.util.UUID;

import io.flutter.plugin.common.MethodChannel;
import no.nordicsemi.android.ble.WriteRequest;
import no.nordicsemi.android.ble.callback.DataReceivedCallback;
import no.nordicsemi.android.ble.callback.DataSentCallback;
import no.nordicsemi.android.ble.data.Data;


public class UARTServiceManager implements GattService {

    private final static UUID UART_SERVICE_UUID = UUID.fromString("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
    private final static UUID UART_RX_CHARACTERISTIC_UUID = UUID.fromString("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
    private final static UUID UART_TX_CHARACTERISTIC_UUID = UUID.fromString("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");

    private BluetoothGattCharacteristic rxCharacteristic, txCharacteristic;

    private BleServiceManager bleServiceManager;
    private OnFinishCallback onDataReceived;

    @Override
    public void initialize() {
        bleServiceManager.setNotificationCallback(txCharacteristic).with(
                new DataReceivedCallback() {
                    @Override
                    public void onDataReceived(@NonNull BluetoothDevice device, @NonNull Data data) {
                        final String text = data.getStringValue(0);
                        System.out.println("\"" + text + "\" received");
                        if (onDataReceived != null) onDataReceived.successOnMain(text);
                        onDataReceived = null;
                    }
                });
        bleServiceManager.enableNotifications(txCharacteristic).enqueue();
    }

    @Override
    public boolean isRequiredServiceSupported(@NonNull BluetoothGatt gatt) {
        final BluetoothGattService service = gatt.getService(UART_SERVICE_UUID);

        if (service != null) {
            rxCharacteristic = service.getCharacteristic(UART_RX_CHARACTERISTIC_UUID);
            txCharacteristic = service.getCharacteristic(UART_TX_CHARACTERISTIC_UUID);
        }

        boolean writeRequest = false;
        boolean writeCommand = false;
        if (rxCharacteristic != null) {
            final int rxProperties = rxCharacteristic.getProperties();
            writeRequest = (rxProperties & BluetoothGattCharacteristic.PROPERTY_WRITE) > 0;
            writeCommand = (rxProperties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) > 0;

            if (writeRequest)
                rxCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        }

        return rxCharacteristic != null && txCharacteristic != null && (writeRequest || writeCommand);
    }

    @Override
    public void onDeviceDisconnected() {
        rxCharacteristic = null;
        txCharacteristic = null;
    }

    @Override
    public void setBleServiceManager(BleServiceManager bleServiceManager) {
        this.bleServiceManager = bleServiceManager;
    }


    public void send(final String text, @NonNull final MethodChannel.Result result) {

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
            final WriteRequest request = bleServiceManager.writeCharacteristic(rxCharacteristic, text.getBytes())
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