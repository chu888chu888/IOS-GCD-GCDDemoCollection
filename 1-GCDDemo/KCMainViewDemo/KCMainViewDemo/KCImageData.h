//
//  KCImageData.h
//  KCMainViewDemo
//
//  Created by chuguangming on 15/3/9.
//  Copyright (c) 2015年 chu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCImageData : NSObject
#pragma mark 索引
@property (nonatomic,assign) int index;

#pragma mark 图片数据
@property (nonatomic,strong) NSData *data;
@end
