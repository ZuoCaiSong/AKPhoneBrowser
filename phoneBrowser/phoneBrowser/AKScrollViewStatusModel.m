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

- (void)loadImageWithCompletedBlock:(void (^)(AKScrollViewStatusModel *, UIImage *, NSData *, NSError *, BOOL, NSURL *))completedBlock{
    _loadImageCompletedBlock = completedBlock;
    
    [self downloadImage];
}

/**开始下载图片*/
-(void)downloadImage{
    weak_self;
    //正在下载
    if(self.operation){
        return;
    }
    
    self.operation = [[SDWebImageManager sharedManager]loadImageWithURL:self.url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        __block UIImage * hasDownImage = image; //已经下载好的图片
        dispatch_async(dispatch_get_main_queue(), ^{
            wself.operation = nil;
            if (wself.loadImageCompletedBlock) {
                wself.loadImageCompletedBlock(wself, image, data, error, finished, imageURL);
            }
            if (error) {
                hasDownImage = [PhotoBrowserManager  defaultManager].errorImage;
                //更新当前model图片的数据
                wself.currentPageImage = hasDownImage;
            }
//                if (hasDownImage.images.count > 0) {
//                    wself.currentPageImage = [PhotoBrowserManager defaultManager].l
//                }
            
        });
    }];
}

@end
