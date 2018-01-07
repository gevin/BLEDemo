//
//  CharacteristicCell.m
//  BLEDemo
//
//  Created by GevinChen on 2017/12/28.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import "CharacteristicCell.h"

@implementation CharacteristicCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.isNew = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
