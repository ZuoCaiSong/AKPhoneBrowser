//
//  AKTapDetectingImageView.m
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "AKTapDetectingImageView.h"
#import "Config.h"

#import "AKScrollViewStatusModel.h"

#import <SDWebImage/FLAnimatedImageView+WebCache.h>

@implementation AKTapDetectingImageView

-(void)setModel:(AKScrollViewStatusModel *)model{
    _model = model;
}

- (void)loadImageWithCompletedBlock:(void (^)(AKScrollViewStatusModel *, UIImage *, NSData *, NSError *, BOOL, NSURL *))completedBlock{
    _loadImageCompletedBlock = completedBlock;
    
    [self downloadImage];
}

/**开始下载图片*/
-(void)downloadImage{
    weak_self;
    //正在下载
    
    
//    if(self.operation){
//        return;
//    }
    /*
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

        });
    }];
     */
    
    [self sd_setImageWithURL:self.model.url placeholderImage:nil options:0 progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (wself.loadImageCompletedBlock) {
            wself.loadImageCompletedBlock(wself.model, image, nil, error, true, imageURL);
        }
    }];
}

@end
