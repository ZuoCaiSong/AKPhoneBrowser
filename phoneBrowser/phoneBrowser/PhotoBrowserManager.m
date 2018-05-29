//
//  PhotoBrowserManager.m
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "PhotoBrowserManager.h"

static inline PhotoBrowserManager * getPhotoBrowserManager(){
    return PhotoBrowserManager
}

static PhotoBrowserManager * mgr = nil;

@implementation PhotoBrowserManager

#pragma mark - 创建一个单例对象

+ (instancetype)defaultManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[self alloc]init];
    });
    return mgr;
}

@end
