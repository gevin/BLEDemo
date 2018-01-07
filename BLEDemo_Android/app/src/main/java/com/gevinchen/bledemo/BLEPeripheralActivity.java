package com.gevinchen.bledemo;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.content.Context;
import android.os.ParcelUuid;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.UUID;

public class BLEPeripheralActivity extends AppCompatActivity {

    Button button_back;
    EditText text_notify;
    EditText text_log;
    Button button_notify;

    BluetoothManager mBluetoothManager;
    BluetoothAdapter mBluetoothAdapter;
    BluetoothGattServer mGattServer;
    BluetoothLeAdvertiser mBluetoothLeAdvertiser;
    BluetoothGattService mBLEService;
    BluetoothGattCharacteristic mBLEChar_write;
    BluetoothGattCharacteristic mBLEChar_read;

    ArrayList<BluetoothDevice> mConnectedDevices = new ArrayList();

    String service_uuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
    String characteristic_write_uuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
    String characteristic_notify_uuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
    String characteristic_read_uuid = "6e400004-b5a3-f393-e0a9-e50e24dcca9e";
    String characteristic_read_uuid_DESC = "00002902-0000-1000-8000-00805f9b34fb";

    byte[] mValue;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bleperipheral);

        setTitle("Peripheral");
        button_back = this.findViewById(R.id.button_back3);
        text_notify = this.findViewById(R.id.editText_notify);
        text_log = this.findViewById(R.id.editText_log);
        button_notify = this.findViewById(R.id.button_notify);


        button_back.setOnClickListener( new Button.OnClickListener(){
            public void onClick( View v)
            {
                stopAdvertising();
                shutdownServer();
                BLEPeripheralActivity.this.finish();
            }
        });

        button_notify.setOnClickListener( new Button.OnClickListener(){
            public void onClick( View v)
            {
                sendNotify(text_notify.getText().toString());
                InputMethodManager imm = ((InputMethodManager)getSystemService(INPUT_METHOD_SERVICE));
                int SoftInputAnchor = R.id.editText_notify;
                imm.hideSoftInputFromWindow(BLEPeripheralActivity.this.getCurrentFocus().getWindowToken(),InputMethodManager.HIDE_NOT_ALWAYS);
            }
        });



        //....
        mBluetoothManager = (BluetoothManager) getSystemService(BLUETOOTH_SERVICE);
        mBluetoothAdapter = mBluetoothManager.getAdapter();
        mGattServer = mBluetoothManager.openGattServer(this, mGattServerCallback);
        mBluetoothLeAdvertiser = mBluetoothAdapter.getBluetoothLeAdvertiser();

        initServer();
        startAdvertising();

    }


    private void initServer() {
        // create service
        mBLEService = new BluetoothGattService(UUID.fromString(service_uuid), BluetoothGattService.SERVICE_TYPE_PRIMARY);

        //  create read/notify char
        mBLEChar_read = new BluetoothGattCharacteristic(UUID.fromString(characteristic_read_uuid),
                        //Read-only characteristic, supports notifications
                        BluetoothGattCharacteristic.PROPERTY_READ | BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                        BluetoothGattCharacteristic.PERMISSION_READ);
        log("Config read char");
        //Descriptor for read notifications
        BluetoothGattDescriptor TX_READ_CHAR_DESC = new BluetoothGattDescriptor( UUID.fromString(characteristic_read_uuid_DESC), BluetoothGattDescriptor.PERMISSION_WRITE);
        mBLEChar_read.addDescriptor(TX_READ_CHAR_DESC);

        // create write char
        mBLEChar_write = new BluetoothGattCharacteristic(UUID.fromString(characteristic_write_uuid),
                        //write permissions
                        BluetoothGattCharacteristic.PROPERTY_WRITE, BluetoothGattCharacteristic.PERMISSION_WRITE);
        log("Config write char");
        // add all char to service
        mBLEService.addCharacteristic(mBLEChar_read);
        mBLEService.addCharacteristic(mBLEChar_write);
        log("Config service");
        //  add service to GattServer
        mGattServer.addService(mBLEService);
        log("Init Gatt Server");
    }

    private void shutdownServer() {
        //mHandler.removeCallbacks(mNotifyRunnable);

        if (mGattServer == null) return;

        mGattServer.close();
        log("Shut Gatt Server");
    }

    /*****************************************
     *  Gatt Server Callback
     ***************************************** */
    private BluetoothGattServerCallback mGattServerCallback = new BluetoothGattServerCallback() {
        @Override
        public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
            super.onConnectionStateChange(device, status, newState);

            String newStateString = "";

            switch (newState){
                case BluetoothProfile.STATE_DISCONNECTED:
                    newStateString = "disconnected";
                    if(mConnectedDevices.size() > 0)mConnectedDevices.remove(device);
                    break;
                case BluetoothProfile.STATE_CONNECTING:
                    newStateString = "connecting";
                    break;
                case BluetoothProfile.STATE_CONNECTED:
                    newStateString = "connected";
                    mConnectedDevices.add(device);
                    log("device:" + device + " connected.");
                    break;
                case BluetoothProfile.STATE_DISCONNECTING:
                    newStateString = "disconnecting";
                    log("device:" + device + " disconnected.");
                    break;
            }

            log("onConnectionStateChange state:" + newStateString);

        }

        @Override
        public void onNotificationSent(BluetoothDevice device, int status)
        {
            super.onNotificationSent(device, status);
        }

        public void onConnectionUpdated(BluetoothDevice gatt, int interval, int latency, int timeout,
                                        int status) {
        }

        @Override
        public void onCharacteristicReadRequest(BluetoothDevice device,
                                                int requestId,
                                                int offset,
                                                BluetoothGattCharacteristic characteristic) {
            super.onCharacteristicReadRequest(device, requestId, offset, characteristic);
            log("onCharacteristicReadRequest " + characteristic.getUuid().toString());

            if (characteristic.getUuid().toString().equals(characteristic_read_uuid)) {
                mGattServer.sendResponse(device,
                        requestId,
                        BluetoothGatt.GATT_SUCCESS,
                        0,
                        mValue);
            }
        }

        // 收到寫入的資料
        @Override
        public void onCharacteristicWriteRequest(BluetoothDevice device,
                                                 int requestId,
                                                 BluetoothGattCharacteristic characteristic,
                                                 boolean preparedWrite,
                                                 boolean responseNeeded,
                                                 int offset,
                                                 byte[] value) {
            super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite,
                    responseNeeded, offset, value);
            log( "onCharacteristicWriteRequest " + characteristic.getUuid().toString());

            if (characteristic_write_uuid.equals(characteristic.getUuid().toString())) {
                // 把寫入的資料記下來
                mValue = value;
                if (responseNeeded) {
                    mGattServer.sendResponse(device,
                            requestId,
                            BluetoothGatt.GATT_SUCCESS,
                            0,
                            value);
                }

                log("Received data : " + stringFromBytes(value) + "\nfrom " + characteristic.getUuid().toString());
            }
        }

        @Override
        public void onDescriptorReadRequest(BluetoothDevice device, int requestId,
                                            int offset, BluetoothGattDescriptor descriptor) {
            super.onDescriptorReadRequest(device, requestId, offset, descriptor);
            log("Our gatt server descriptor was read.");
        }

        @Override
        public void onDescriptorWriteRequest(BluetoothDevice device, int requestId,
                                             BluetoothGattDescriptor descriptor,
                                             boolean preparedWrite, boolean responseNeeded, int offset, byte[] value) {
            super.onDescriptorWriteRequest(device, requestId, descriptor, preparedWrite, responseNeeded, offset, value);
            log("Our gatt server descriptor was written.");

            //NOTE: Its important to send response. It expects response else it will disconnect
            if (responseNeeded) {
                mGattServer.sendResponse(device,
                        requestId,
                        BluetoothGatt.GATT_SUCCESS,
                        0,
                        value);

            }

        }

    };


    /*****************************************
     *  notify
     ***************************************** */
    void sendNotify(String text){
        if( text == null || text.length()==0 ) return;
        if( mConnectedDevices == null || mConnectedDevices.size() == 0) return;
        mBLEChar_read.setValue(text);
        if(mBLEChar_read.getValue().length == 0 ) return;
        for ( BluetoothDevice device : mConnectedDevices ) {
            mGattServer.notifyCharacteristicChanged( device, mBLEChar_read, false);
        }
        log("notify " + text);
    }

    /*****************************************
     *  Advertising
     ***************************************** */
    private void startAdvertising() {
        if (mBluetoothLeAdvertiser == null) {
            return;
        }
        AdvertiseSettings settings = new AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
                .setConnectable(true)
                .setTimeout(0)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_LOW)
                .build();
        AdvertiseData data = new AdvertiseData.Builder()
                .setIncludeDeviceName(true) // 顯示 DEVICE NAME
                .addServiceUuid( new ParcelUuid(UUID.fromString(service_uuid)) )
                .build();
        mBluetoothLeAdvertiser.startAdvertising(settings, data, mAdvertiseCallback);
        log("start advertising");
    }

    private AdvertiseCallback mAdvertiseCallback = new AdvertiseCallback() {
        @Override
        public void onStartSuccess(AdvertiseSettings settingsInEffect) {
            log("Peripheral advertising started.");
        }

        @Override
        public void onStartFailure(int errorCode) {
            log("Peripheral advertising failed: " + errorCode);
        }
    };

    private void stopAdvertising() {
        if (mBluetoothLeAdvertiser != null) {
            mBluetoothLeAdvertiser.stopAdvertising(mAdvertiseCallback);
            log("stop advertising");
        }
    }

    /*****************************************
     *  log
     ***************************************** */
    public void log( String text ){
        Log.v("Log", text);
        final String text1 = text;
        runOnUiThread(new Runnable() {
            public void run() {
                String newString = text_log.getText().toString() + text1 + "\n";
                text_log.setText(newString);
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
