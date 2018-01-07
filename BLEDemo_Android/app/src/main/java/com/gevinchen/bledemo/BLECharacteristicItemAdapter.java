package com.gevinchen.bledemo;


import android.bluetooth.BluetoothGattCharacteristic;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;

/**
 * Created by gevinchen on 2018/1/4.
 */

public class BLECharacteristicItemAdapter extends BaseAdapter {

    public interface WriteClickedDelegate{
        public void writeClicked(BluetoothGattCharacteristic characteristic, String text);
    }

    private WriteClickedDelegate mClickedDelegate;

    private ArrayList<BluetoothGattCharacteristic> dataList;   //資料
    private LayoutInflater inflater;    //用來取得此 itemView 定義的 layout

    //初始化
    public BLECharacteristicItemAdapter(ArrayList<BluetoothGattCharacteristic> dataList, LayoutInflater inflater, WriteClickedDelegate delegate){
        this.dataList= dataList;
        this.inflater = inflater;
        this.mClickedDelegate = delegate;
    }

    // 下面四個 METHOD 是在自訂 custom adapter 要實作的
    //取得數量
    @Override
    public int getCount() {
        return this.dataList.size();
    }
    //取得Item
    @Override
    public Object getItem(int position) {
        return (BluetoothGattCharacteristic)this.dataList.get(position);
    }

    //此範例沒有特別設計ID所以隨便回傳一個值
    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {

        BluetoothGattCharacteristic characteristic = this.dataList.get(position);

        //當ListView被拖拉時會不斷觸發getView，為了避免重複加載必須加上這個判斷
        if (convertView == null) {
            // 透過 inflater 以 id my_itemview 來載入 item view 的實體
            // 這邊就類似 IOS 的 create view from xib
            convertView = inflater.inflate(R.layout.blecharacteristic_item, null);
            EditText editText = convertView.findViewById(R.id.editText_ch_write);
            final Button button = convertView.findViewById(R.id.button_ch_write);
            HashMap map = new HashMap();
            map.put("characteristic", characteristic );
            map.put("editText",editText);
            button.setTag(map);
            button.setOnClickListener( new Button.OnClickListener(){
                public void onClick( View v)
                {
                    HashMap map = (HashMap )v.getTag();
                    BluetoothGattCharacteristic ch = (BluetoothGattCharacteristic)map.get("characteristic");
                    EditText editText = (EditText)map.get("editText");
                    mClickedDelegate.writeClicked( ch, editText.getText().toString());
                }
            });
        }

        //  取出資料
        String description = characteristic.toString();
        int properties = characteristic.getProperties();
        String propertyString = "";
        if((properties & 1) > 0) propertyString = propertyString + " Broadcast";
        if((properties & 2) > 0) propertyString = propertyString + " Read";
        if((properties & 4) > 0) {
            propertyString = propertyString + " WriteWithoutResponse";
        }
        if((properties & 8) > 0){
            propertyString = propertyString + " Write";
        }
        if((properties & 16) > 0){
            propertyString = propertyString + " Notify";
        }
        if((properties & 32) > 0) propertyString = propertyString + " Indicate";
        if((properties & 64) > 0) propertyString = propertyString + " AuthenticatedSignedWrites";
        if((properties & 128) > 0) propertyString = propertyString + " ExtendedProperties";
        if((properties & 256) > 0) propertyString = propertyString + " NotifyEncryptionRequired";
        if((properties & 512) > 0) propertyString = propertyString + " IndicateEncryptionRequired";
        if(propertyString.length() == 0) propertyString = "none";

        if((properties & 4) > 0 || (properties & 8) > 0){
            propertyString = "Write";
            EditText editText = convertView.findViewById(R.id.editText_ch_write);
            Button button = convertView.findViewById(R.id.button_ch_write);
            button.setVisibility(View.VISIBLE);
            editText.setVisibility(View.VISIBLE);

        }
        else{
            EditText editText = convertView.findViewById(R.id.editText_ch_write);
            Button button = convertView.findViewById(R.id.button_ch_write);
            button.setVisibility(View.INVISIBLE);
            editText.setVisibility(View.INVISIBLE);
        }
        String uuidstr = characteristic.getUuid().toString();
        String value = "";
        byte[] byteArr = characteristic.getValue();
        if(byteArr != null && byteArr.length > 0 ) {
            try {
                value = new String(characteristic.getValue(), "utf-8");
            } catch (UnsupportedEncodingException e) {
            }
        }

        // 取出 sub view
        TextView textUUID = convertView.findViewById(R.id.textView_ch_uuid);
        TextView textPro  = convertView.findViewById(R.id.textView_ch_properties);
        TextView textValue = convertView.findViewById(R.id.textView_ch_value);
        // 填入資料
        textUUID.setText("uuid:" + uuidstr);
        textPro.setText("properties:" + propertyString);
        textValue.setText("value:"+value);

        return convertView;
    }





}
