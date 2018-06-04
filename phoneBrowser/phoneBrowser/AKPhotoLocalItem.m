//
//  AKPhotoLocalItem.m
//  phoneBrowser
//
//  Created by LEO on 2018/6/4.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "AKPhotoLocalItem.h"

@implementation AKPhotoLocalItem

- (instancetype)initWithImage:(UIImage *)image frame:(CGRect)frame{
    
    AKPhotoLocalItem * item = [[AKPhotoLocalItem alloc]init];
    item.localImage = image;
    item.frame = frame;
    
    return item;
}

@end
