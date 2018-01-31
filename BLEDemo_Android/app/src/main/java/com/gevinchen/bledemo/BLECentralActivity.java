package com.gevinchen.bledemo;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Handler;
import android.os.ParcelUuid;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.view.View;
import android.content.Intent;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;


//import com.gevinchen.bledemo.PermissionDetector;

public class BLECentralActivity extends AppCompatActivity {

    //  自訂 request code
    private static final int PERMISSION_REQUEST_COARSE_LOCATION = 1;

    Button btnBack;
    Button btnScan;
    Button btnStopScan;
    ProgressBar spinner_scan;
    BluetoothManager mBluetoothManager;
    BluetoothAdapter mBluetoothAdapter;
    BluetoothLeScanner mLeScanner;


    ListView listView;

    //此ArrayList屬性為String，用來裝Devices Name
    ArrayList<String> deviceNames = new ArrayList<String>();
    ArrayList<BluetoothDevice> mBluetoothDevices=new ArrayList<BluetoothDevice>();
    ArrayAdapter listAdapter;

    Handler mHandler;

//    PermissionDetector mPermissionDetector;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_blecentral);

        setTitle("Central");
//        getActionBar().setIcon(R.drawable.my_icon);

        btnBack = this.findViewById(R.id.button_back);
        btnScan = this.findViewById(R.id.button_scan);
        btnStopScan = this.findViewById(R.id.button_stopscan);
        spinner_scan = this.findViewById(R.id.progressBar_scan);
        listView = this.findViewById(R.id.listView_devices);
        /**
         * Gevin note: 第一次執行時遇到 java.lang.SecurityException: Need ACCESS_COARSE_LOCATION or ACCESS_FINE_LOCATION permission to get scan results
         *
         * 解法:
         * 1 在 manifest 文件加入權限：
         *  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
         *  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
         *
         * 2 在 Activity 中呼叫 requestPermissions() 來請求權限，系統會彈出請求權限的對話框
         * 3 覆寫 Activity 的 onRequestPermissionsResult() 方法，接收請求權限的結果
         * */
        // 請求權限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android M Permission check
            if (this.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(new String[]{Manifest.permission.ACCESS_COARSE_LOCATION}, PERMISSION_REQUEST_COARSE_LOCATION);
            }
        }

        //利用getPackageManager().hasSystemFeature()檢查手機是否支援BLE設備，否則利用finish()關閉程式。
        if(!getPackageManager().hasSystemFeature(getPackageManager().FEATURE_BLUETOOTH_LE)){
            Toast.makeText(getBaseContext(),"unsupport ble",Toast.LENGTH_SHORT).show();
            finish();
        }

        // 試著取得 BluetoothAdapter，如果 BluetoothAdapter == null，則該手機不支援 Bluetooth
        // 取得 Adapter 之前，需先使用 BluetoothManager，此為系統層級需使用 getSystemService
        mBluetoothManager = (BluetoothManager)this.getSystemService(BLUETOOTH_SERVICE);
        mBluetoothAdapter = mBluetoothManager.getAdapter();

        // 如果 == null，利用 finish() 取消程式。
        if(mBluetoothAdapter==null){
            Toast.makeText(getBaseContext(),"unsupport ble",Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        mLeScanner = mBluetoothAdapter.getBluetoothLeScanner();

        // ListView 使用的 Adapter，
        listAdapter = new ArrayAdapter<String>(getBaseContext(),android.R.layout.simple_expandable_list_item_1,deviceNames);
        // 將 listView 綁上 Adapter
        listView.setAdapter(listAdapter);
        // 綁上 OnItemClickListener，設定 ListView 點擊觸發事件
        listView.setOnItemClickListener(new ListViewOnItemClickListener());
        mHandler = new Handler();

        btnBack.setOnClickListener( new Button.OnClickListener(){
            public void onClick( View v)
            {
                BLECentralActivity.this.finish();
            }
        });

        //  開始搜尋 BLE 設備
        btnScan.setOnClickListener( new Button.OnClickListener(){
            public void onClick( View v)
            {
                // 5 秒後停止掃瞄
                startScan(5);
            }
        });

        // 停止搜尋 BLE 設備
        btnStopScan.setOnClickListener( new Button.OnClickListener(){
            public void onClick( View v)
            {
                stopScan();
            }
        });
    }

    /*****************************************
     *  ListView Item Click
     *
     ***************************************** */

    /**
     *  List View 按下 ITEM 時觸發的 CALL BACK
     *
     * */
    private class ListViewOnItemClickListener implements AdapterView.OnItemClickListener{

        @Override
        public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
            BluetoothDevice device = mBluetoothDevices.get(position);
            Intent intent = new Intent(BLECentralActivity.this,BLEPeripheralConnectActivity.class);
            intent.putExtra("Device", device);
            startActivity(intent);
        }
    }

    /*****************************************
     *  掃瞄 Device
     *
     ***************************************** */

    /* 開始搜尋 BLE 設備，5秒後停止 */
    void startScan( int seconds )
    {
        mBluetoothDevices.clear();
        if(spinner_scan.getVisibility() == View.INVISIBLE) {
            // 開始搜尋 BLE 設備
            mLeScanner.startScan(mDeviceLeScanCallback);
            // 5秒後停止搜尋
            mHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    stopScan();
                }
            }, seconds * 1000);
            spinner_scan.setVisibility(View.VISIBLE);
        }
    }

    /* 停止搜尋 BLE 設備 */
    void stopScan()
    {
        mLeScanner.stopScan( mDeviceLeScanCallback );
        spinner_scan.setVisibility(View.INVISIBLE);
    }


    /**
     *  掃瞄發現 DEVICE 的 CALLBACK
     *
     * */
    public ScanCallback mDeviceLeScanCallback = new ScanCallback () {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            byte[] scanData = result.getScanRecord().getBytes();

            Log.e("BLECentralScan","onScanResult :" + bytesToHex(scanData));
            Log.e("BLECentralScan","onScanResult :" + result.getScanRecord().toString());
            BluetoothDevice device = result.getDevice();
            int rssi = result.getRssi();
            if(!mBluetoothDevices.contains(device)){
                mBluetoothDevices.add(device);
                deviceNames.add( device.getName() + " rssi:" + rssi + "\naddress:" + device.getAddress() );
                listAdapter.notifyDataSetChanged();
            }

        }

        @Override
        public void onBatchScanResults(List<ScanResult> results) {
            super.onBatchScanResults(results);
        }

        @Override
        public void onScanFailed(int errorCode) {
            super.onScanFailed(errorCode);
        }
    };


    /*****************************************
     *
     *
     ***************************************** */

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


    /* user回應請求權限的 callback */
    @Override
    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults)
    {
        switch (requestCode) {
            case PERMISSION_REQUEST_COARSE_LOCATION:
                if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // TODO request success

                }
                break;
        }
    }

}
