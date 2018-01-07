//
//  PeripheralViewController.h
//  BLEDemo
//
//  Created by GevinChen on 2017/12/16.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BLECentralController : UIViewController
@property (nonatomic) CBCentralManager *centerManager;
@property (nonatomic) CBPeripheral *peripheral;
@property (nonatomic) NSDictionary *advertismentData;

@end
