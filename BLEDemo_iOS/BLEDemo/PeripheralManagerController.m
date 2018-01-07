//
//  PeripheralManagerController.m
//  BLEDemo
//
//  Created by GevinChen on 2017/12/29.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import "PeripheralManagerController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface PeripheralManagerController () <CBPeripheralManagerDelegate, UITextFieldDelegate>
{
    CBPeripheralManager *_peripheralManager;
    
    CBUUID *_serviceUUID;
    CBUUID *_ch_write_UUID;
    CBUUID *_ch_read_UUID;
    CBUUID *_ch_notify_UUID;
    
    CBMutableService *_service;
    NSData *_writeData;
    CBMutableCharacteristic *_characteristic_write;
    CBMutableCharacteristic *_characteristic_notify;
}

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *buttonNotify;


@end

@implementation PeripheralManagerController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"peripheral";
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    self.textField.delegate = self;

    // 用不合格式的 uuid 會 crash
    _serviceUUID = [CBUUID UUIDWithString: @"A3243425-22B7-43BC-B71C-AD44367F36DD"];
    _ch_write_UUID = [CBUUID UUIDWithString: @"A3243425-22B7-43BC-B71C-AD44367F36DD"];
    _ch_notify_UUID = [CBUUID UUIDWithString: @"A3243426-22B7-43BC-B71C-AD44367F36DD"];
    _ch_read_UUID  = [CBUUID UUIDWithString: @"A3243427-22B7-43BC-B71C-AD44367F36DD"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_peripheralManager stopAdvertising];
}


#pragma mark - UIButton Action

- (IBAction)notifyClicked:(id)sender 
{
    [self notify: self.textField.text];
}

- (IBAction)clearClicked:(id)sender
{
    self.textView.text = @"";
}



#pragma mark - CBPeripheralManagerDelegate


/*
 *  設備狀態變更
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state != CBManagerStatePoweredOn) {
        return;
    }
    
//    CBManagerStateUnknown = 0,
//    CBManagerStateResetting,
//    CBManagerStateUnsupported,
//    CBManagerStateUnauthorized,
//    CBManagerStatePoweredOff,
//    CBManagerStatePoweredOn,
    NSLog(@"self.peripheralManager powered on.");
    
    //--------------------------
    // write characteristic
    //--------------------------
    _characteristic_write = [[CBMutableCharacteristic alloc] initWithType:_ch_write_UUID
                                                               properties:CBCharacteristicPropertyWrite
                                                                    value:nil
                                                              permissions:CBAttributePermissionsWriteable];
//    CBUUID *ch_write_DescriptorUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];//or set it to the actual UUID->2901
//    CBMutableDescriptor *ch_write_Descriptor = [[CBMutableDescriptor alloc]initWithType:ch_write_DescriptorUUID value:@"Write iPhone"];
//    _characteristic_write.descriptors = @[ch_write_Descriptor];
    
    //--------------------------
    // notify characteristic
    //--------------------------
    _characteristic_notify = [[CBMutableCharacteristic alloc] initWithType:_ch_notify_UUID
                                                                properties:CBCharacteristicPropertyNotify
                                                                     value:nil
                                                               permissions:CBAttributePermissionsReadable];
//    CBUUID *ch_notify_DescriptorUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];//or set it to the actual UUID->2901
//    CBMutableDescriptor *ch_notify_Descriptor = [[CBMutableDescriptor alloc]initWithType:ch_notify_DescriptorUUID value:@"Notify from iPhone"];
//    _characteristic_notify.descriptors = @[ch_notify_Descriptor];

    //--------------------------
    //  config service
    //--------------------------
    _service = [[CBMutableService alloc] initWithType:_serviceUUID primary:YES];
    _service.characteristics = @[_characteristic_write, _characteristic_notify];
    [_peripheralManager addService:_service];
    
    //--------------------------
    //  advertisment data
    //--------------------------
    NSDictionary *advertisingData = @{CBAdvertisementDataLocalNameKey : @"iPhone",
                                      CBAdvertisementDataServiceUUIDsKey : @[_serviceUUID],
                                      };
    [_peripheralManager startAdvertising:advertisingData];
    
}



/*
 *  收到寫入的資料
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    NSLog(@"didReceiveWriteRequests");
    
    CBATTRequest*       request = [requests  objectAtIndex: 0];
    NSData*             request_data = request.value;
    CBCharacteristic*   write_char = request.characteristic;
    
    if([write_char.UUID.UUIDString isEqualToString: _ch_write_UUID.UUIDString ] ){
        //取得 Requset 中的 Value, //回應 Requset
        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        _writeData = request_data;
        NSString *str = [[NSString alloc] initWithData:request_data encoding:NSUTF8StringEncoding];
        str = [NSString stringWithFormat:@"receive:%@", str];
        [self addLog:str];
        [self scrollOutputToBottom];
    }
}


/*
 *  收到讀取請求
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    [self addLog:@"did receive read request."];
    NSString *uuid = [[request.characteristic UUID] UUIDString];
    if([uuid isEqualToString:[_ch_read_UUID UUIDString]]){
        [request setValue:_writeData];
        //透過 Response 將字串值回傳
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        //回應 Requset
    }
}


/*
 *  
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary<NSString *, id> *)dict
{
    
}

/*
 *  開始發佈 advertising data
 */
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(nullable NSError *)error
{
    if (error) {
        [self addLog: [NSString stringWithFormat:@"Error advertising: %@", [error localizedDescription]] ];
    }
    else{
        [self addLog:@"start advertising."];
    }
}


/*
 *  加入 service 完成 
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(nullable NSError *)error
{
    [self addLog:[NSString stringWithFormat:@"did add service:%@", service.UUID.UUIDString ]];
}


/*
 *  有人訂閱這部device
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    // 
    [self addLog:[NSString stringWithFormat:@"did subscribe characteristic:%@", characteristic.UUID.UUIDString ]];
    // 這裡可以把 central 存下來，這樣在 notify 的時候，就可以控制個別發送不同的 notify 內容
}


/*
 *  有人取消訂閱
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    [self addLog:[NSString stringWithFormat:@"did unsubscribe characteristic:%@", characteristic.UUID.UUIDString ]];
}

/*!
 *  @method peripheralManagerIsReadyToUpdateSubscribers:
 *  @param peripheral   The peripheral manager providing this update.
 *  @discussion         This method is invoked after a failed call to @link updateValue:forCharacteristic:onSubscribedCentrals: @/link, when <i>peripheral</i> is again
 *                      ready to send characteristic value updates.
 *
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    [self addLog:@"peripheral ready to update subscribers."];
}



#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Control

- (void)notify:(NSString*)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [_peripheralManager updateValue:data forCharacteristic:_characteristic_notify onSubscribedCentrals:nil];
    [self addLog:[NSString stringWithFormat:@"notify %@", string]];
}

- (void)addLog:(NSString*)string
{
    self.textView.text = [NSString stringWithFormat:@"%@%@\n", self.textView.text, string]; 
}

- (void)scrollOutputToBottom {
    CGPoint p = [self.textView contentOffset];
    [self.textView setContentOffset:p animated:NO];
    [self.textView scrollRangeToVisible:NSMakeRange([self.textView.text length], 0)];
}

@end
