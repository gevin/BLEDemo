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
    CBUUID *_ch_notify_UUID;
    
    CBMutableService *_service;
    
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
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    self.textField.delegate = self;

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




#pragma mark - CBPeripheralManagerDelegate


/*!
 *  @method peripheralManagerDidUpdateState:
 *
 *  @param peripheral   The peripheral manager whose state has changed.
 *
 *  @discussion         Invoked whenever the peripheral manager's state has been updated. Commands should only be issued when the state is 
 *                      <code>CBPeripheralManagerStatePoweredOn</code>. A state below <code>CBPeripheralManagerStatePoweredOn</code>
 *                      implies that advertisement has paused and any connected centrals have been disconnected. If the state moves below
 *                      <code>CBPeripheralManagerStatePoweredOff</code>, advertisement is stopped and must be explicitly restarted, and the
 *                      local database is cleared and all services must be re-added.
 *
 *  @see                state
 *
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
    // 用不合格式的 uuid 會 crash
    _serviceUUID = [CBUUID UUIDWithString: @"A3243425-22B7-43BC-B71C-AD44367F36DD"];
    _ch_write_UUID = [CBUUID UUIDWithString: @"49BC4442-F0C6-4755-A309-D7592A5AFA23"];
    _ch_notify_UUID = [CBUUID UUIDWithString: @"0CE7A115-BAD7-4263-A06B-01EE822A9E49"];
    
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



/*!
 *  @method peripheralManager:didReceiveWriteRequests:
 *
 *  @param peripheral   The peripheral manager requesting this information.
 *  @param requests     A list of one or more <code>CBATTRequest</code> objects.
 *
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request or command for one or more characteristics with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link should be called exactly once. If <i>requests</i> contains
 *                      multiple requests, they must be treated as an atomic unit. If the execution of one of the requests would cause a failure, the request
 *                      and error reason should be provided to <code>respondToRequest:withResult:</code> and none of the requests should be executed.
 *
 *  @see                CBATTRequest
 *
 */
// 收到資料
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    NSLog(@"didReceiveWriteRequests");
    
    CBATTRequest*       request = [requests  objectAtIndex: 0];
    NSData*             request_data = request.value;
    CBCharacteristic*   write_char = request.characteristic;
    
    if([write_char.UUID.UUIDString isEqualToString: _ch_write_UUID.UUIDString ] ){
        //取得 Requset 中的 Value, //回應 Requset
        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        NSString *str = [[NSString alloc] initWithData:request_data encoding:NSUTF8StringEncoding];
        str = [NSString stringWithFormat:@"receive:%@", str];
        [self addLog:str];
        [self scrollOutputToBottom];
    }
}


/*!
 *  @method peripheralManager:didReceiveReadRequest:
 *
 *  @param peripheral   The peripheral manager requesting this information.
 *  @param request      A <code>CBATTRequest</code> object.
 *
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request for a characteristic with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link must be called.
 *
 *  @see                CBATTRequest
 *
 */
// 收到讀取
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    [self addLog:@"did receive read request."];
//    NSString *uuid = [[request.characteristic UUID] UUIDString];
//    if([uuid isEqualToString:_ch_notify_UUID]){
//        [request setValue:[_string_rwvalue dataUsingEncoding:NSUTF8StringEncoding]];
//        //透過 Response 將字串值回傳
//        [_peripheral respondToRequest:request withResult:CBATTErrorSuccess];
//        //回應 Requset
//    }
}


/*!
 *  @method peripheralManager:willRestoreState:
 *
 *  @param peripheral    The peripheral manager providing this information.
 *  @param dict            A dictionary containing information about <i>peripheral</i> that was preserved by the system at the time the app was terminated.
 *
 *  @discussion            For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
 *                        the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
 *                        Bluetooth system.
 *
 *  @seealso            CBPeripheralManagerRestoredStateServicesKey;
 *  @seealso            CBPeripheralManagerRestoredStateAdvertisementDataKey;
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary<NSString *, id> *)dict
{
    
}

/*!
 *  @method peripheralManagerDidStartAdvertising:error:
 *
 *  @param peripheral   The peripheral manager providing this information.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method returns the result of a @link startAdvertising: @/link call. If advertisement could
 *                      not be started, the cause will be detailed in the <i>error</i> parameter.
 *
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


/*!
 *  @method peripheralManager:didAddService:error:
 *
 *  @param peripheral   The peripheral manager providing this information.
 *  @param service      The service that was added to the local database.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method returns the result of an @link addService: @/link call. If the service could
 *                      not be published to the local database, the cause will be detailed in the <i>error</i> parameter.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(nullable NSError *)error
{
    [self addLog:[NSString stringWithFormat:@"did add service:%@", service.UUID.UUIDString ]];
}


/*!
 *  @method peripheralManager:central:didSubscribeToCharacteristic:
 *
 *  @param peripheral       The peripheral manager providing this update.
 *  @param central          The central that issued the command.
 *  @param characteristic   The characteristic on which notifications or indications were enabled.
 *
 *  @discussion             This method is invoked when a central configures <i>characteristic</i> to notify or indicate.
 *                          It should be used as a cue to start sending updates as the characteristic value changes.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    // 有人訂閱這部device
    [self addLog:[NSString stringWithFormat:@"did subscribe characteristic:%@", characteristic.UUID.UUIDString ]];
    // 這裡可以把 central 存下來，這樣在 notify 的時候，就可以控制個別發送不同的 notify 內容
}


/*!
 *  @method peripheralManager:central:didUnsubscribeFromCharacteristic:
 *
 *  @param peripheral       The peripheral manager providing this update.
 *  @param central          The central that issued the command.
 *  @param characteristic   The characteristic on which notifications or indications were disabled.
 *
 *  @discussion             This method is invoked when a central removes notifications/indications from <i>characteristic</i>.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    // 有人取消訂閱
    [self addLog:[NSString stringWithFormat:@"did unsubscribe characteristic:%@", characteristic.UUID.UUIDString ]];
}

/*!
 *  @method peripheralManagerIsReadyToUpdateSubscribers:
 *
 *  @param peripheral   The peripheral manager providing this update.
 *
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
