package com.gevinchen.bledemo;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListAdapter;
import android.widget.ListView;
import android.widget.ProgressBar;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;



/*
 Gevin note:


 1. 連線至 DEVICE
    BluetoothGattCallback gattClientCallback = new GattClientCallback();
    BluetoothGatt mGatt = device.connectGatt(this, false, gattClientCallback);

 2. 當連接 DEVICE 成功後，搜尋 Service
    在 onConnectionStateChange 時，狀態為 BluetoothProfile.STATE_CONNECTED，執行下面程式
    mGatt.discoverServices();

    執行後會觸發 public void onServicesDiscovered(BluetoothGatt gatt, int status)
    用下面指令取出 BluetoothGattService
    List <BluetoothGattService>services = gatt.getServices();

 3. 取得 Service 裡的 Characteristic
    在 public void onServicesDiscovered(BluetoothGatt gatt, int status) 裡

    List<BluetoothGattCharacteristic> characteristicsList = service.getCharacteristics();
    for (BluetoothGattCharacteristic characteristic : characteristicsList ){
        int properties = characteristic.getProperties();
        String uuidstr = characteristic.getUuid().toString();
        String value = "";
        byte[] byteArr = characteristic.getValue();
        if(byteArr != null && byteArr.length > 0 ) {
            try {
                value = new String(characteristic.getValue(), "utf-8");
            } catch (UnsupportedEncodingException e) {
            }
        }
        Log.v("BLECharacteristic","description:" + characteristic.toString() + "\nproperty:" + properties + "," + propertyString + "\nvalue:" + value + "\nuuid:" + uuidstr);
    }

    取出 Characteristic 後，依 Characteristic 的 properties 來決定它能做什麼事

 4. 註冊接收 notify
    boolean characteristicWriteSuccess = gatt.setCharacteristicNotification(characteristic, true);


 5. 讀取資料

    // 主動讀取資料
    mGatt.readCharacteristic( characteristic )
    //  主動讀取 Characteristic 後會觸發
    public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic,
    //  當 Characteristic 發出 notify 會觸發
    public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic)

    // 取出資料
    byte[] messageBytes = characteristic.getValue();
    log("Read: " + bytesToHex(messageBytes));
    String message = stringFromBytes(messageBytes);



 6. 寫入資料

    byte[] messageBytes = bytesFromString(text);
    characteristic.setValue(messageBytes);
    boolean success = mGatt.writeCharacteristic(characteristic);

    這邊要注意 characteristic 的 properties 必須要有 4 或 8

 */

public class BLEPeripheralConnectActivity extends AppCompatActivity {


    private String service_uuid = "A3243425-22B7-43BC-B71C-AD44367F36DD";
    private String characteristic_write_uuid = "49BC4442-F0C6-4755-A309-D7592A5AFA23";
    private String characteristic_notify_uuid = "0CE7A115-BAD7-4263-A06B-01EE822A9E49";
    private String descriptor_client_characteristic_Configuration = "2902";

    BluetoothDevice device;
    BluetoothGatt mGatt;
    GattClientCallback gattClientCallback;

    ProgressBar progressBar_discover;
    Button btnBack;
    EditText editText;

//    Button btnWrite;
//    EditText editText_write;

    ArrayList mServices = new ArrayList();
    ArrayList mCharacteristic = new ArrayList();

    ListView listView_ch;
    BLECharacteristicItemAdapter mLstAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bleperipheral_connect);

        device = this.getIntent().getExtras().getParcelable("Device");
        connectDevice(device);

        btnBack = this.findViewById(R.id.button_back2);
        editText = this.findViewById(R.id.editText3);
        editText.setMaxLines(1000);
        editText.setShowSoftInputOnFocus(false);
        editText.setFocusable(false);
        progressBar_discover = this.findViewById(R.id.progressBar_discover);

//        btnWrite = this.findViewById(R.id.button_write);
//        editText_write = this.findViewById(R.id.editText4);
        listView_ch = this.findViewById( R.id.listView_ch);

        LayoutInflater inflater = (LayoutInflater) getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        mLstAdapter = new BLECharacteristicItemAdapter(mCharacteristic, inflater, new BLECharacteristicItemAdapter.WriteClickedDelegate() {
            @Override
            public void writeClicked(BluetoothGattCharacteristic characteristic, String text) {
            sendMessage( text, characteristic);
            }
        });

        listView_ch.setAdapter(mLstAdapter);

        btnBack.setOnClickListener( new Button.OnClickListener(){
            public void onClick( View v)
            {
                disconnectGattServer();
                BLEPeripheralConnectActivity.this.finish();
            }
        });


    }


    /*****************************************
     *  連到 Peripheral
     *
     ***************************************** */
    /* 連到 peripheral */
    private void connectDevice(BluetoothDevice device) {
        gattClientCallback = new GattClientCallback();
        mGatt = device.connectGatt(this, false, gattClientCallback);
    }

    public void disconnectGattServer() {
        if (mGatt != null) {
            mGatt.disconnect();
            mGatt.close();
        }
    }

    public void sendMessage( String text, BluetoothGattCharacteristic characteristic ){
        byte[] messageBytes = bytesFromString(text);
        characteristic.setValue(messageBytes);
        boolean success = mGatt.writeCharacteristic(characteristic);
        if (success) {
            log("Wrote: " + text);
        } else {
            log("Failed to write data");
        }
    }


    // 連 PERIPHERAL 的 CALLBACK
    private class GattClientCallback extends BluetoothGattCallback {

        /**
         * Callback triggered as result of {@link BluetoothGatt#setPreferredPhy}, or as a result of
         * remote device changing the PHY.
         *
         * @param gatt GATT client
         * @param txPhy the transmitter PHY in use. One of {@link BluetoothDevice#PHY_LE_1M},
         *             {@link BluetoothDevice#PHY_LE_2M}, and {@link BluetoothDevice#PHY_LE_CODED}.
         * @param rxPhy the receiver PHY in use. One of {@link BluetoothDevice#PHY_LE_1M},
         *             {@link BluetoothDevice#PHY_LE_2M}, and {@link BluetoothDevice#PHY_LE_CODED}.
         * @param status Status of the PHY update operation.
         *                  {@link BluetoothGatt#GATT_SUCCESS} if the operation succeeds.
         */
//        public void onPhyUpdate(BluetoothGatt gatt, int txPhy, int rxPhy, int status) {
//        }

        /**
         * Callback triggered as result of {@link BluetoothGatt#readPhy}
         *
         * @param gatt GATT client
         * @param txPhy the transmitter PHY in use. One of {@link BluetoothDevice#PHY_LE_1M},
         *             {@link BluetoothDevice#PHY_LE_2M}, and {@link BluetoothDevice#PHY_LE_CODED}.
         * @param rxPhy the receiver PHY in use. One of {@link BluetoothDevice#PHY_LE_1M},
         *             {@link BluetoothDevice#PHY_LE_2M}, and {@link BluetoothDevice#PHY_LE_CODED}.
         * @param status Status of the PHY read operation.
         *                  {@link BluetoothGatt#GATT_SUCCESS} if the operation succeeds.
         */
//        public void onPhyRead(BluetoothGatt gatt, int txPhy, int rxPhy, int status) {
//        }

        /**
         * Callback indicating when GATT client has connected/disconnected to/from a remote
         * GATT server.
         *
         * @param gatt GATT client
         * @param status Status of the connect or disconnect operation.
         *               {@link BluetoothGatt#GATT_SUCCESS} if the operation succeeds.
         * @param newState Returns the new connection state. Can be one of
         *                  {@link BluetoothProfile#STATE_DISCONNECTED} or
         *                  {@link BluetoothProfile#STATE_CONNECTED}
         */
        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            super.onConnectionStateChange(gatt, status, newState);
            if (status == BluetoothGatt.GATT_FAILURE) {
                disconnectGattServer();
                log("Gatt failure");
                return;
            } else if (status != BluetoothGatt.GATT_SUCCESS) {
                disconnectGattServer();
                return;
            }
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                log("Gatt Server connected");
                mGatt.discoverServices();
                log("discover services");
                runOnUiThread(new Runnable() {
                                  public void run() {
                                      progressBar_discover.setVisibility(View.VISIBLE);
                                  }
                });
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                log("Gatt disconnected");
                disconnectGattServer();
            }
        }

        /**
         * Callback invoked when the list of remote services, characteristics and descriptors
         * for the remote device have been updated, ie new services have been discovered.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#discoverServices}
         * @param status {@link BluetoothGatt#GATT_SUCCESS} if the remote device
         *               has been explored successfully.
         */
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            super.onServicesDiscovered(gatt, status);

            if (status != BluetoothGatt.GATT_SUCCESS) {
                log("Device service discovery unsuccessful, status " + status);
                return;
            }

            List <BluetoothGattService>services = gatt.getServices();

            for ( BluetoothGattService service : services){
                String serviceDesc = service.getUuid().toString();
                Log.v("BLEService",serviceDesc);
                List<BluetoothGattCharacteristic> characteristicsList = service.getCharacteristics();
                for (BluetoothGattCharacteristic characteristic : characteristicsList ){
                    String description = characteristic.toString();
                    int properties = characteristic.getProperties();

                    String uuidstr = characteristic.getUuid().toString();
                    String value = "";
                    byte[] byteArr = characteristic.getValue();
                    if(byteArr != null && byteArr.length > 0 ) {
                        try {
                            value = new String(characteristic.getValue(), "utf-8");
                        }
                        catch (UnsupportedEncodingException e) {
                        }
                    }
                    Log.v("BLECharacteristic","description:" + characteristic.toString() + "\nproperty:" + properties + "\nvalue:" + value + "\nuuid:" + uuidstr);
                }
            }

            runOnUiThread(new Runnable() {
                public void run() {
                List<BluetoothGattService> services = mGatt.getServices();
                for ( BluetoothGattService service : services) {
                    // 這個 uuid 的 service 我才載入，因為這是我另一支 iphone 程式的 service
                    List<BluetoothGattCharacteristic> ch_list = service.getCharacteristics();
                    for (BluetoothGattCharacteristic characteristic : ch_list) {
                        if (!characteristic.getService().getUuid().toString().toUpperCase().equals(service_uuid)) {
                            continue;
                        }
                        mCharacteristic.add(characteristic);
                        mLstAdapter.notifyDataSetChanged();
                    }
                }
                progressBar_discover.setVisibility(View.INVISIBLE);
                }
            });
        }

        /**
         * Callback reporting the result of a characteristic read operation.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#readCharacteristic}
         * @param characteristic Characteristic that was read from the associated
         *                       remote device.
         * @param status {@link BluetoothGatt#GATT_SUCCESS} if the read operation
         *               was completed successfully.
         */
        public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic,
                                         int status) {
            super.onCharacteristicRead(gatt, characteristic, status);
            if (status == BluetoothGatt.GATT_SUCCESS) {
                log("Characteristic read successfully");
                readCharacteristic(characteristic);
            } else {
                log("Characteristic read unsuccessful, status: " + status);
                // Trying to read from the Time Characteristic? It doesnt have the property or permissions
                // set to allow this. Normally this would be an error and you would want to:
                // disconnectGattServer();
            }
        }

        /**
         * Callback indicating the result of a characteristic write operation.
         *
         * <p>If this callback is invoked while a reliable write transaction is
         * in progress, the value of the characteristic represents the value
         * reported by the remote device. An application should compare this
         * value to the desired value to be written. If the values don't match,
         * the application must abort the reliable write transaction.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#writeCharacteristic}
         * @param characteristic Characteristic that was written to the associated
         *                       remote device.
         * @param status The result of the write operation
         *               {@link BluetoothGatt#GATT_SUCCESS} if the operation succeeds.
         */
        public void onCharacteristicWrite(BluetoothGatt gatt,
                                          BluetoothGattCharacteristic characteristic, int status) {
            super.onCharacteristicWrite(gatt, characteristic, status);
            if (status == BluetoothGatt.GATT_SUCCESS) {
                log("Characteristic written successfully");
            } else {
                log("Characteristic write unsuccessful, status: " + status);
                //mClientActionListener.disconnectGattServer();
            }
        }

        /**
         * Callback triggered as a result of a remote characteristic notification.
         *
         * @param gatt GATT client the characteristic is associated with
         * @param characteristic Characteristic that has been updated as a result
         *                       of a remote notification event.
         */
        public void onCharacteristicChanged(BluetoothGatt gatt,
                                            BluetoothGattCharacteristic characteristic) {

            super.onCharacteristicChanged(gatt, characteristic);
            log("Characteristic changed, " + characteristic.getUuid().toString());
            readCharacteristic(characteristic);
        }

        /**
         * Callback reporting the result of a descriptor read operation.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#readDescriptor}
         * @param descriptor Descriptor that was read from the associated
         *                   remote device.
         * @param status {@link BluetoothGatt#GATT_SUCCESS} if the read operation
         *               was completed successfully
         */
//        public void onDescriptorRead(BluetoothGatt gatt, BluetoothGattDescriptor descriptor,
//                                     int status) {
//        }

        /**
         * Callback indicating the result of a descriptor write operation.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#writeDescriptor}
         * @param descriptor Descriptor that was writte to the associated
         *                   remote device.
         * @param status The result of the write operation
         *               {@link BluetoothGatt#GATT_SUCCESS} if the operation succeeds.
         */
//        public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor,
//                                      int status) {
//        }

        /**
         * Callback invoked when a reliable write transaction has been completed.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#executeReliableWrite}
         * @param status {@link BluetoothGatt#GATT_SUCCESS} if the reliable write
         *               transaction was executed successfully
         */
//        public void onReliableWriteCompleted(BluetoothGatt gatt, int status) {
//        }

        /**
         * Callback reporting the RSSI for a remote device connection.
         *
         * This callback is triggered in response to the
         * {@link BluetoothGatt#readRemoteRssi} function.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#readRemoteRssi}
         * @param rssi The RSSI value for the remote device
         * @param status {@link BluetoothGatt#GATT_SUCCESS} if the RSSI was read successfully
         */
//        public void onReadRemoteRssi(BluetoothGatt gatt, int rssi, int status) {
//        }

        /**
         * Callback indicating the MTU for a given device connection has changed.
         *
         * This callback is triggered in response to the
         * {@link BluetoothGatt#requestMtu} function, or in response to a connection
         * event.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#requestMtu}
         * @param mtu The new MTU size
         * @param status {@link BluetoothGatt#GATT_SUCCESS} if the MTU has been changed successfully
         */
//        public void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
//        }

        /**
         * Callback indicating the connection parameters were updated.
         *
         * @param gatt GATT client involved
         * @param interval Connection interval used on this connection, 1.25ms unit. Valid
         *            range is from 6 (7.5ms) to 3200 (4000ms).
         * @param latency Slave latency for the connection in number of connection events. Valid
         *            range is from 0 to 499
         * @param timeout Supervision timeout for this connection, in 10ms unit. Valid range is
         *            from 10 (0.1s) to 3200 (32s)
         * @param status {@link BluetoothGatt#GATT_SUCCESS} if the connection has been updated
         *                successfully
         * @hide
         */
        public void onConnectionUpdated(BluetoothGatt gatt, int interval, int latency, int timeout,
                                        int status) {
        }

        // 註冊接收通知
        private void subscribeNotification(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
            if(!characteristic.getUuid().toString().toUpperCase().equals(characteristic_notify_uuid)) return;
            //  註冊
            boolean characteristicWriteSuccess = gatt.setCharacteristicNotification(characteristic, true);
            if (characteristicWriteSuccess) {
                log("Characteristic notification set successfully for " + characteristic.getUuid().toString());

                UUID uuid = UUID.fromString(characteristic_notify_uuid);
                List<BluetoothGattDescriptor> descriptors = characteristic.getDescriptors();
                for ( BluetoothGattDescriptor descriptor : descriptors ){
                    Log.v("BLEDescriptor","uuid:" + descriptor.getUuid().toString());
                    // client characteristic Configuration 0x2902
                    if(descriptor.getUuid().toString().substring(4,8).equals("2902")) {
                        descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                        gatt.writeDescriptor(descriptor);
                        log("enable Descriptor:" + descriptor.getUuid().toString());
                    }
                }
            } else {
                log("Characteristic notification set failure for " + characteristic.getUuid().toString());
            }
        }

        //  取得 Characteristic 資料，Read 跟 Changed 都會觸發這裡
        private void readCharacteristic(BluetoothGattCharacteristic characteristic) {
            byte[] messageBytes = characteristic.getValue();
//            log("Read: " + bytesToHex(messageBytes));
            String message = stringFromBytes(messageBytes);
            if (message == null) {
                log("Unable to convert bytes to string");
                return;
            }

            log("Received message: " + message);
        }
    }

    public void log( String text ){
        Log.v("Log", text);
        final String text1 = text;
        runOnUiThread(new Runnable() {
            public void run() {
                String newString = editText.getText().toString() + text1 + "\n";
                editText.setText(newString);
            }
        });
//        String newString = editText.getText().toString() + text + "\n";
//        editText.setText(newString);
    }

    /* byte array 轉成 hex string */
    private final static char[] hexArray = "0123456789ABCDEF".toCharArray();
    public static String bytesToHex(byte[] bytes) {
        char[] hexChars = new char[bytes.length * 2];
        for ( int j = 0; j < bytes.length; j++ ) {
            int v = bytes[j] & 0xFF;
            hexChars[j * 2] = hexArray[v >>> 4];
            hexChars[j * 2 + 1] = hexArray[v & 0x0F];
        }
        return new String(hexChars);
    }

    public static String stringFromBytes(byte[] bytes) {
        String byteString = null;
        try {
            byteString = new String(bytes, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            Log.e("exception", "Unable to convert message bytes to string");
        }
        return byteString;
    }

    public static byte[] bytesFromString(String string) {
        byte[] stringBytes = new byte[0];
        try {
            stringBytes = string.getBytes("UTF-8");
        } catch (UnsupportedEncodingException e) {
            Log.e("exception", "Failed to convert message string to byte array");
        }

        return stringBytes;
    }

}
