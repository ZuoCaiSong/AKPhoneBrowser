//
//  AKScrollViewStatusModel.m
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "AKScrollViewStatusModel.h"

#import <SDWebImage/SDWebImageManager.h>

#import <SDWebImage/FLAnimatedImageView+WebCache.h>

#import "Config.h"
#import "PhotoBrowserManager.h"
@implementation AKScrollViewStatusModel

-(instancetype)init{
    
    self = [super init];
    if (self) {
        self.scale = @1; //初始化的时候,图片的放大倍数默认为1
        self.contentOffset = CGPointZero;
    }
    return self;
}

@end
