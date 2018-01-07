//
//  ViewController.m
//  BLEDemo
//
//  Created by GevinChen on 2017/12/15.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import "BLEPeripheralScanController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#import "BLECentralController.h"

@interface BLEPeripheralScanController () <UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate>
{
    //藍牙設備的管理物件，可透過它去掃瞄、連接週邊設備
    CBCentralManager *_centralManager;
    //記錄掃瞄發現的週邊設備
    NSMutableArray *_peripherals;    
    
    NSDictionary *_advertismentDict;
    UIActivityIndicatorView *_spinnerView;
    
    BOOL firstScan;
}

@property (weak, nonatomic) IBOutlet UIButton *btnScan;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation BLEPeripheralScanController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Scan";
    // 初始化主設備物件，配置 CBCentralManagerDelegate 的 delegate 與 queue 執行緒，若給 nil 預設指定用 main thread
    _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
    _peripherals = [[NSMutableArray alloc] init];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self initSpinner];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(!firstScan){
        firstScan = YES;
        [self startScan];
    }
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

#pragma mark - Button Action

- (IBAction)debugClicked:(id)sender {
    [self performSegueWithIdentifier:@"PeripheralViewController" sender:nil];    
}

- (IBAction)btnScanClicked:(id)sender {
    [self startScan];
}

- (void)startScan
{
    [_peripherals removeAllObjects];
    [self.tableView reloadData];
    // 開始掃瞄週邊設備
    /*
     第一個參數給 nil 就是掃瞄所有的週邊設備，不然的話就給予指定的 uuid array
     掃到設備後，就會呼叫
     - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
     */
    [_centralManager scanForPeripheralsWithServices:nil options:nil];
    NSLog(@"start scan");
    [self performSelector:@selector(stopScan) withObject:nil afterDelay:5];
    [self showSpinner];
}

- (void)stopScan
{
    [_centralManager stopScan];
    NSLog(@"stop scan");
    [self hideSpinner];
}


#pragma mark - CBCentralManagerDelegate

// 主設備狀態改變後會觸發，在 CBCentralManagerStatePoweredOn 狀態才是正確開啟
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBManagerStateUnknown:
            NSLog(@">>> CBCentralManagerStateUnknown");
            break;
        case CBManagerStateResetting:
            NSLog(@">>> CBCentralManagerStateResetting");
            break;
        case CBManagerStateUnsupported:
            NSLog(@">>> CBCentralManagerStateUnsupported");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@">>> CBCentralManagerStateUnauthorized");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@">>> CBCentralManagerStatePoweredOff");
            break;
        case CBManagerStatePoweredOn:
            NSLog(@">>> CBCentralManagerStatePoweredOn");
        default:
            break;
    }
}

// 掃瞄到週邊設備後，會進入
- (void)centralManager:(CBCentralManager *)central 
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData 
                  RSSI:(NSNumber *)RSSI{
    NSLog(@"掃瞄到週邊設備:%@",peripheral.name);
    NSLog(@"RSSI:%f", [RSSI floatValue]);
    
    NSLog(@"data:\n%@",advertisementData);
    _advertismentDict = advertisementData;
    int index = 0;
    BOOL find = NO;
    for (CBPeripheral *c_peripheral in _peripherals) {
        if ([c_peripheral.name isEqualToString:peripheral.name]){
            find = YES;
            break;
        }
        index++;
    }
    
    if(find){
        [_peripherals replaceObjectAtIndex:index withObject:peripheral];
    }
    else{
        [_peripherals addObject:peripheral];
    }
    [self.tableView reloadData];
    [self hideSpinner];
}

// 連接週邊設備 成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@">>>連接到設備（%@）成功",peripheral.name);
    [self performSegueWithIdentifier:@"PeripheralViewController" sender:peripheral];

}

// 連接週邊設備 失敗
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@">>>連接到設備（%@）失败,原因:%@",[peripheral name],[error localizedDescription]);
}

// 斷開週邊設備
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@">>>斷開連接設備（%@）: %@\n", [peripheral name], [error localizedDescription]);
    if(self.presentedViewController){
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}



#pragma mark - UITableViewDelegate


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _peripherals.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(cell==nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    CBPeripheral *peripheral = _peripherals[indexPath.row];
    cell.textLabel.text = peripheral.name;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    /*
     一個主設備最多能連7個週邊設備，每個週邊設備最多只能给一個主設備連接,連接成功，失敗，斷開 會進入各自的方法裡
     - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的委托
     - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败的委托
     - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设的委托
     */
    CBPeripheral *peripheral = _peripherals[indexPath.row];
    // 連接週邊設備
    [_centralManager connectPeripheral:peripheral options:nil];
}

#pragma mark - Navi

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"viewController segue %@", segue.identifier);
    if ([segue.identifier isEqualToString:@"PeripheralViewController"]){
        BLECentralController *vc = segue.destinationViewController;
        vc.centerManager = _centralManager;
        vc.peripheral = sender;
        vc.advertismentData = _advertismentDict;
    }
    
}

@end
