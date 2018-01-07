//
//  AppDelegate.h
//  BLEDemo
//
//  Created by GevinChen on 2017/12/15.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

