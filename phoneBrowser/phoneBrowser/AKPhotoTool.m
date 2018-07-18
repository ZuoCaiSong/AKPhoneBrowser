//
//  AKPhotoTool.m
//  phoneBrowser
//
//  Created by LEO on 2018/7/18.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "AKPhotoTool.h"

#import <SDWebImage/SDImageCache.h> //缓存
#import <SDWebImage/SDWebImageManager.h> //管理


@implementation AKPhotoTool


#pragma mark - 根据URL获取缓存的图片

+ (UIImage *)getCacheImageForUrl:(NSURL *)url{
    if (!url) {
        return nil;
    }
    SDImageCache * imageCache = [SDImageCache sharedImageCache];
    
    //1 获取图片缓存时对应的key
    NSString*cacheImageKey = [[SDWebImageManager sharedManager]cacheKeyForURL:url];
    
    //2 获取缓存的图片
    return [imageCache  imageFromCacheForKey:cacheImageKey];
}

@end
