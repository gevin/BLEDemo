//
//  PeripheralViewController.m
//  BLEDemo
//
//  Created by GevinChen on 2017/12/16.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import "BLECentralController.h"
#import "CharacteristicCell.h"

@interface BLECentralController () <CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
    NSMutableArray *_servicesList;
    
    NSMutableDictionary *_characteristicsListDict;
    
    NSMutableDictionary *_nibViewDict;
    
    BOOL firstScan;
    
    UIActivityIndicatorView *_spinnerView;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelRSSI;
@property (weak, nonatomic) IBOutlet UILabel *labelDistance;
@property (weak, nonatomic) IBOutlet UITextView *textLog;

@end

@implementation BLECentralController


- (void)viewDidLoad
{
    [super viewDidLoad];
    _characteristicsListDict = [[NSMutableDictionary alloc] init];
    _servicesList = [[NSMutableArray alloc] init];
    _nibViewDict = [[NSMutableDictionary alloc] init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    UINib *nib = [UINib nibWithNibName:@"CharacteristicCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"CharacteristicCell"];
    self.tableView.estimatedRowHeight = 105;
    
    NSArray *arr = [nib instantiateWithOwner:nil options:nil];
    UIView *prototype_view_CharacteristicCell  = arr[0];
    _nibViewDict[@"CharacteristicCell"] = prototype_view_CharacteristicCell; 
    
    self.title = @"Central";
    _peripheral.delegate = self;
    self.labelName.text = [NSString stringWithFormat:@"name:%@",_peripheral.name];
    [_peripheral readRSSI];
    //掃瞄外設Services，成功後會進入方法：
    // -(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
//    [_peripheral discoverServices:nil];
//    NSLog(@"%s",__FUNCTION__);
    
    [self initSpinner];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    NSLog(@"%s",__FUNCTION__);

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    NSLog(@"%s",__FUNCTION__);
    if(!firstScan){
        firstScan = YES;
        [_peripheral discoverServices:nil];
        [self showSpinner];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //  disconnect peripheral
    [self.centerManager cancelPeripheralConnection:self.peripheral];
}

#pragma mark - Log

- (void)addLog:(NSString*)string
{
    self.textLog.text = [NSString stringWithFormat:@"%@%@\n", self.textLog.text, string]; 
}

#pragma mark - Button Action

- (IBAction)scanServiceClicked:(id)sender
{
    [_servicesList removeAllObjects];
    [_peripheral discoverServices:nil];
}

#pragma mark - UIActivityIndicator

- (void)initSpinner
{
    _spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_spinnerView];
    _spinnerView.hidden = YES;
}

- (void)showSpinner
{
    _spinnerView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    _spinnerView.hidden = NO;
    [_spinnerView startAnimating];
}

- (void)hideSpinner
{
    _spinnerView.hidden = YES;
    [_spinnerView stopAnimating];
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView*)tableView sectionForSectionIndexTitle:(nonnull NSString *)title atIndex:(NSInteger)index
{
    return _servicesList.count;
}

//- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    if(_servicesList.count==0){
//        return nil;
//    } 
//    CBService *service = _servicesList[section];
//    if(service){
//        return [service.UUID description];
//    }
//    return nil;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(_servicesList.count==0){
        return 0;
    } 
    CBService *service = _servicesList[section];
    NSValue *value = [NSValue valueWithNonretainedObject:service];
    NSMutableArray *charList = _characteristicsListDict[value];
    
    if(charList==nil){
        return 0;
    }
    
    return charList.count;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    CBService *service = _servicesList[indexPath.section];
    NSValue *value = [NSValue valueWithNonretainedObject:service];
    NSMutableArray *charList = _characteristicsListDict[value];
    CBCharacteristic *characteristic = indexPath.row < charList.count ? charList[indexPath.row] : nil; 
    
    if(characteristic == nil ) return  44;
    
    UIView *view = _nibViewDict[@"CharacteristicCell"];
//    NSLog(@"%d height:%f", indexPath.row, view.frame.size.height );
    if (view != nil){
        return view.frame.size.height;
    }
    else{
        return 44;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CBService *service = _servicesList[indexPath.section];
    NSValue *value = [NSValue valueWithNonretainedObject:service];
    NSMutableArray *charList = _characteristicsListDict[value];
    CBCharacteristic *characteristic = indexPath.row < charList.count ? charList[indexPath.row] : nil;
    
    CharacteristicCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CharacteristicCell"];
    if (cell==nil){
        UINib *nib = [UINib nibWithNibName:@"CharacteristicCell" bundle:nil];
        [self.tableView registerNib:nib forCellReuseIdentifier:@"CharacteristicCell"];
        
        NSArray *arr = [nib instantiateWithOwner:nil options:nil];
        cell = arr[0];
    }
    
    if(cell.isNew){
        cell.isNew = NO;
        [cell.btnRead addTarget:self
                         action:@selector(readClicked:) 
               forControlEvents:UIControlEventTouchUpInside];
        [cell.btnWrite addTarget:self
                          action:@selector(writeClicked:) 
                forControlEvents:UIControlEventTouchUpInside];
        cell.btnRead.tag = indexPath.row;
        cell.btnWrite.tag = indexPath.row;
        cell.textField.delegate = self;
    }
    
    cell.btnRead.hidden = YES;
    cell.btnWrite.hidden = YES;
    cell.textField.hidden = YES;
    
    if(characteristic == nil) return cell;
    
    // uuid
    cell.labelCharacteristicDesc.text = [characteristic.UUID description];
    
    // properties
    [cell setMode:characteristic.properties];
    [cell setProperty:characteristic.properties];
       
    // descriptor
    int i=0;
    NSMutableString *mstring = [[NSMutableString alloc] initWithCapacity:100];
    [mstring appendString:@"description:"];
    for (CBDescriptor *d in characteristic.descriptors) {
        [mstring appendFormat:@"%d. %@, ", i+1, [d.UUID description]];
        i++;
    }
    cell.labelDescriptor.text = mstring;

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //CBService *service = _servicesList[indexPath.row];
    
}

#pragma mark - UIButton Action

- (void)readClicked:(UIButton*)sender
{
//    CharacteristicCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
    CBService *service = _servicesList[0];
    NSValue *value = [NSValue valueWithNonretainedObject:service];
    NSMutableArray *charList = _characteristicsListDict[value];
    CBCharacteristic *characteristic = charList[sender.tag];
    [self addLog:[NSString stringWithFormat:@"read characteristic: %@", characteristic.UUID]];
    [self.peripheral readValueForCharacteristic:characteristic];
}

- (void)writeClicked:(UIButton*)sender
{
    CharacteristicCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
    CBService *service = _servicesList[0];
    NSValue *value = [NSValue valueWithNonretainedObject:service];
    NSMutableArray *charList = _characteristicsListDict[value];
    CBCharacteristic *characteristic = charList[sender.tag];
    [self addLog:[NSString stringWithFormat:@"write characteristic: %@", cell.textField.text]];
    
    [self writeCharacteristic:self.peripheral characteristic:characteristic value:[cell.textField.text dataUsingEncoding:NSUTF8StringEncoding] ];
}


#pragma mark - CBPeripheralDelegate

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(nullable NSError *)error{
//    NSLog(@"peripheral >>> Update RSSI");
    [peripheral readRSSI];
}

// 當執行 [peripheral readRSSI] 時，會呼叫此方法
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error{
//    NSLog(@"peripheral >>> Read RSSI");
    if (error){
        NSString *errorStr = [NSString stringWithFormat:@">>> Read RSSI for %@ with error: %@", peripheral.name, [error localizedDescription] ];
        [self addLog:errorStr];
        return;
    }
    [self addLog:[NSString stringWithFormat:@"RSSI:%@", [RSSI stringValue]]];
    self.labelRSSI.text = [NSString stringWithFormat:@"rssi:%@",[RSSI stringValue]];
    CGFloat ci = ([RSSI intValue] - 49) / (10 * 4.);
    CGFloat distance = pow(10,ci);
    self.labelDistance.text = [NSString stringWithFormat:@"distance:%.1f", distance];

}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error
{
//    NSLog(@"peripheral >>> Discover Included Services For Service");
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
//    NSLog(@"peripheral >>> Update Notification State For Characteristic");
}

- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral{
//    NSLog(@"peripheral >>> Peripheral Is Ready To Send Write Without Response");
}

- (void)peripheral:(CBPeripheral *)peripheral didOpenL2CAPChannel:(nullable CBL2CAPChannel *)channel error:(nullable NSError *)error{
//    NSLog(@"peripheral >>> Did Open L2CAP Channel");
}

- (void)peripheral:(CBPeripheral*)peripheral didModifyServices:(nonnull NSArray<CBService *> *)invalidatedServices
{
//    NSLog(@"peripheral >>> Did Modify Services");
    // 
    int i=0;
    while (_servicesList.count>i) {
        CBService *mservice = _servicesList[i];
        for (CBService *cservice in invalidatedServices) {
            if([[mservice.UUID UUIDString] isEqualToString:[cservice.UUID UUIDString]]){
                [_servicesList removeObject:mservice];
                continue;
            }
        }
        i++;
    }
    
    if(_servicesList.count==0){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}



#pragma mark - Service
//  掃瞄到 Services
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
//    NSLog(@">>> Discover services ");
    if (error){
//        NSLog(@">>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    
//    printf("--------- peripheral ---------\n");
//    printf("services\n");
    int i=0;
    for (CBService *service in peripheral.services){
        //NSLog(@"service %@",[service.UUID UUIDString]);
        NSArray *characteristicArr = [service characteristics];
//        printf("%d. %s, characteristic count:%d\n", i+1, [[service.UUID description] UTF8String], characteristicArr.count);
        [_servicesList addObject:service];
        NSValue *value = [NSValue valueWithNonretainedObject:service];
        _characteristicsListDict[value] = [[NSMutableArray alloc] init];
        // 掃瞄到 service 的 Characteristics 後，會進入下面的方法
        // -(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
        [_peripheral discoverCharacteristics:nil forService:service];
        i++;
    }
//    [self.tableView reloadData];
}

//  掃瞄到 characteristics
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error{
    
    NSValue *value = [NSValue valueWithNonretainedObject:service];
    NSMutableArray *charList = _characteristicsListDict[value];
//    printf("--------- service ---------\n");
//    printf("%s\n", [[service.UUID description] UTF8String]);
//    printf("---------------------------\n");
//    printf("characteristic\n");
    int i=0;
    for (CBCharacteristic *characteristic in service.characteristics) {
//        printf("%d. %s\n", i+1, [[characteristic.UUID UUIDString] UTF8String]);
        
        [charList addObject:characteristic];
        if(characteristic.properties & CBCharacteristicPropertyNotify){
            [self notifyCharacteristic:self.peripheral characteristic:characteristic];
        }
        i++;
    }
    
    
    // 讀取 Characteristic 的值，若讀到資料，會進入方法
    // -(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
    for (CBCharacteristic *characteristic in service.characteristics){
        [peripheral readValueForCharacteristic:characteristic];
    }
    
    // 搜索 Characteristic 的 Descriptors，讀到資料會進入方法
    // -(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
    for (CBCharacteristic *characteristic in service.characteristics){
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
}


#pragma mark - Characteristic

//獲取的charateristic的值，收到 notify 或是執行 read 都會進入此方法
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
//    NSLog(@"Characteristic >>> Update Value");
    
    //印出characteristic的UUID和值
    NSString *valueString = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
//    NSLog(@"characteristic uuid:%@  value:%@",characteristic.UUID,valueString);
    [self addLog:[NSString stringWithFormat:@"receive:%@ \nfrom:%@",valueString,characteristic.UUID]];
    
    [self.tableView reloadData];
    [self hideSpinner];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
//    NSLog(@"Characteristic >>> Did Write Value");
    [self addLog:@"write success!"];
}


#pragma mark - Descriptors

//搜索到Characteristic的Descriptors
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
//    NSLog(@">>> Characteristic Discover Descriptors");
    //印出Characteristic和他的Descriptors
//    NSLog(@"characteristic uuid:%@",characteristic.UUID);
//    printf("--------- characteristic ---------\n");
//    printf("%s\n", [[characteristic.UUID description] UTF8String]);
//    NSString *valueString = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
//    printf("value:%s\n",[valueString UTF8String] );
//    printf("----------------------------------\n");
//    printf("Descriptor\n");
//    int i=0;
//    for (CBDescriptor *d in characteristic.descriptors) {
//        printf("%d. %s\n", i+1, [[d.UUID description] UTF8String]);
//        i++;
//    }
    [self.tableView reloadData];

}

// 獲取到 Descriptors 的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
//    NSLog(@"Descriptor >>> Update Value ");
    // 印出 DescriptorsUUID 和value
    // descriptor 通常是對 characteristic 的描述，所以通常是字串資料
    [self.tableView reloadData];

}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
//    NSLog(@"Descriptor >>> Write Value ");

    
}



#pragma mark - write

// 寫入資料
-(void)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value{
    // 印出 characteristic 的權限
    // 可以發現有很多種，一個 characteristic 可以同時有多種 properties 例如可以同時是 read, notify，或是同時是 read write
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast            = 0x01,
     CBCharacteristicPropertyRead            = 0x02,
     CBCharacteristicPropertyWriteWithoutResponse        = 0x04,
     CBCharacteristicPropertyWrite            = 0x08,
     CBCharacteristicPropertyNotify            = 0x10,
     CBCharacteristicPropertyIndicate            = 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites        = 0x40,
     CBCharacteristicPropertyExtendedProperties          = 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)  = 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0) = 0x200
     };
    */
    
    NSLog(@"%lu", (unsigned long)characteristic.properties);
    // Note: 測試起來傳給 android 一次只能傳 20 字，不曉得是不是 andoroid 的限制
    // https://github.com/don/cordova-plugin-ble-central/issues/234
    //只有 characteristic.properties 有 write 的權限才可以寫入
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        [self addLog:@"該字段不可寫入！"];
    }
}


#pragma mark - Subscribe


// 訂閱
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    // 收到通知的資料後，會進入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    
}

// 取消訂閱
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}




#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}




@end

