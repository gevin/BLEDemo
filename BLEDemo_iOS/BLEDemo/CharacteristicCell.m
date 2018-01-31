//
//  CharacteristicCell.m
//  BLEDemo
//
//  Created by GevinChen on 2017/12/28.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import "CharacteristicCell.h"
#import <CoreBluetooth/CoreBluetooth.h>
@implementation CharacteristicCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.isNew = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setMode:(NSUInteger)property
{
    self.constraint_Label_Desc_bottom.constant = 8;
    self.btnWrite.hidden = YES;
    self.btnRead.hidden = YES;
    self.textField.hidden = YES;
    
    if(property & CBCharacteristicPropertyRead ||
       property & CBCharacteristicPropertyNotify){
        self.btnRead.hidden = NO;
    }
    if(property & CBCharacteristicPropertyWriteWithoutResponse || 
       property & CBCharacteristicPropertyWrite ){            
        self.btnWrite.hidden = NO;
        self.textField.hidden = NO;
        self.textField.text = @"";
        self.constraint_Label_Desc_bottom.constant = 41;
    }
}

- (void)setProperty:(NSUInteger)property
{
    NSMutableString *propertiesString = [[NSMutableString alloc] initWithCapacity:100];
    if(property & CBCharacteristicPropertyBroadcast){
        [propertiesString appendString:@"Broadcast "];
    }
    if(property & CBCharacteristicPropertyRead){
        [propertiesString appendString:@"Read "];
    }
    if(property & CBCharacteristicPropertyWriteWithoutResponse){            
        [propertiesString appendString:@"WriteWithoutResponse "];
    }
    if(property & CBCharacteristicPropertyWrite){
        [propertiesString appendString:@"Write "];
    }
    if(property & CBCharacteristicPropertyNotify){
        [propertiesString appendString:@"Notify "]; 
    }
    if(property & CBCharacteristicPropertyIndicate){
        [propertiesString appendString:@"Indicate "];
    }
    if(property & CBCharacteristicPropertyAuthenticatedSignedWrites){
        [propertiesString appendString:@"AuthenticatedSignedWrites "];
    }
    if(property & CBCharacteristicPropertyExtendedProperties){
        [propertiesString appendString:@"ExtendedProperties "];
    }
    if(property & CBCharacteristicPropertyNotifyEncryptionRequired){
        [propertiesString appendString:@"NotifyEncryptionRequired "];
    }
    if(property & CBCharacteristicPropertyIndicateEncryptionRequired){
        [propertiesString appendString:@"IndicateEncryptionRequired "];
    }
    if(propertiesString.length==0){
        [propertiesString appendString:@"unknown "];
    }
    self.labelProperty.text = propertiesString;
}

@end
