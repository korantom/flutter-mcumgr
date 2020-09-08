package com.korantom.flutter_mcumgr;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.content.Context;
import android.os.Handler;
import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.UUID;

import io.flutter.plugin.common.MethodChannel;
import no.nordicsemi.android.ble.BleManager;
import no.nordicsemi.android.ble.WriteRequest;
import no.nordicsemi.android.ble.callback.DataReceivedCallback;
import no.nordicsemi.android.ble.callback.DataSentCallback;
import no.nordicsemi.android.ble.data.Data;

public class UARTManager extends BleManager {

    public UARTManager(@NonNull Context context) {
        super(context);
    }

    public UARTManager(@NonNull Context context, @NonNull Handler handler) {
        super(context, handler);
    }

    /* ------------------------------------------------------------------------------------------ */

    private final static UUID UART_SERVICE_UUID = UUID.fromString("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
    private final static UUID UART_RX_CHARACTERISTIC_UUID = UUID.fromString("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
    private final static UUID UART_TX_CHARACTERISTIC_UUID = UUID.fromString("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");

    private BluetoothGattCharacteristic rxCharacteristic, txCharacteristic;
    private OnFinishCallback onFinish;

    /* ------------------------------------------------------------------------------------------ */

    @NonNull
    @Override
    protected BleManagerGattCallback getGattCallback() {
        return new UARTManagerGattCallback();
    }

    /**
     * BluetoothGatt callbacks for connection/disconnection, service discovery,
     * receiving indication, etc.
     */
    private class UARTManagerGattCallback extends BleManagerGattCallback {

        @Override
        protected void initialize() {
            setNotificationCallback(txCharacteristic).with(
                    new DataReceivedCallback() {
                        @Override
                        public void onDataReceived(@NonNull BluetoothDevice device, @NonNull Data data) {
                            final String text = data.getStringValue(0);
                            System.out.println("\"" + text + "\" received");
                            if (onFinish != null) onFinish.successOnMain(text);
                            onFinish = null;
                        }
                    });
            requestMtu(260).enqueue();
            enableNotifications(txCharacteristic).enqueue();
        }

        @Override
        public boolean isRequiredServiceSupported(@NonNull final BluetoothGatt gatt) {
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
        protected void onDeviceDisconnected() {
            rxCharacteristic = null;
            txCharacteristic = null;
        }
    }

    /**
     * Sends the given text to RX characteristic.
     *
     * @param text the text to be sent
     */
    public void send(final String text, @NonNull final MethodChannel.Result result) {

        if (rxCharacteristic == null || onFinish != null)
            return;

        onFinish = new OnFinishCallback() {
            @Override
            public void success(Object message) {
                result.success(message);
            }

            @Override
            void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
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
