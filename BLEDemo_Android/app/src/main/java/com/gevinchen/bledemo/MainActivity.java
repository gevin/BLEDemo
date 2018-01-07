package com.gevinchen.bledemo;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.widget.Button;
import android.view.View;
import android.content.Intent;
import com.gevinchen.bledemo.BLECentralActivity;
import com.gevinchen.bledemo.BLEPeripheralActivity;

import static android.content.Intent.FLAG_ACTIVITY_REORDER_TO_FRONT;


public class MainActivity extends AppCompatActivity {

    Button btnCentral;
    Button btnPeripheral;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        btnCentral = this.findViewById(R.id.button_central);
        btnPeripheral = this.findViewById(R.id.button_peripheral);

        btnCentral.setOnClickListener( new Button.OnClickListener(){
            public void onClick(View v)
            {
                // 移去 BLECentralActivity
                Intent intent = new Intent();
                intent.setClass( MainActivity.this, BLECentralActivity.class);
                intent.setFlags( FLAG_ACTIVITY_REORDER_TO_FRONT );
                startActivity(intent);
//                MainActivity.this.finish();

                /*
                * Gevin note:
                * 如果執行 MainActivity.this.finish(); 的話，當前的 Activity 就會直接結束釋放
                * 如果想要像 ios 那樣，前一個 controller 仍會保留在 memory
                * 就改為不要執行 MainActivity.this.finish(); 且在 startActivity 之前
                * 設定 intent.setFlags( FLAG_ACTIVITY_REORDER_TO_FRONT );
                * 表示新的 Activity 要放在 stack 的最上
                *
                * */

            }

        });

        btnPeripheral.setOnClickListener( new Button.OnClickListener(){
            public void onClick(View v)
            {
                // 移去 BLEPeripheralActivity
                Intent intent = new Intent();
                intent.setClass( MainActivity.this, BLEPeripheralActivity.class);
                intent.setFlags( FLAG_ACTIVITY_REORDER_TO_FRONT );
                startActivity(intent);
            }

        });


    }
}
