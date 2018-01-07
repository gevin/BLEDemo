//
//  CharacteristicCell.h
//  BLEDemo
//
//  Created by GevinChen on 2017/12/28.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CharacteristicCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelCharacteristicDesc;
@property (weak, nonatomic) IBOutlet UILabel *labelProperty;
@property (weak, nonatomic) IBOutlet UILabel *labelValue;
@property (weak, nonatomic) IBOutlet UILabel *labelDescriptor;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *btnRead;
@property (weak, nonatomic) IBOutlet UIButton *btnWrite;
@property (nonatomic) BOOL isNew; 

@end
