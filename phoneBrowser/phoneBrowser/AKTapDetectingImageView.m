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
#import "PhotoBrowserManager.h"
#import "PhotoBrowserView.h"

#import <SDWebImage/FLAnimatedImageView+WebCache.h>
#import "NSData+ImageContentType.h"

#import "AKPhotoTool.h"

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
   
    //移除下载任务
    
    NSOperation *  operation = [[SDWebImageManager sharedManager]loadImageWithURL:self.model.url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
       
        
        //移除下载任务
        [PhotoBrowserManager.defaultManager.photoBrowserView.preloadingOperationDic removeObjectForKey: @(self.model.index)];
        
//        SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:data];
//        if (imageFormat == SDImageFormatGIF) {
//            self.animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
//            self.image = nil;
//        } else {
//            self.image = image;
//            self.animatedImage = nil;
//        }
        dispatch_async(dispatch_get_main_queue(), ^{
           
            if (wself.loadImageCompletedBlock) {
                wself.loadImageCompletedBlock(wself.model, image, data, error, finished, imageURL);
             }
        });
    }];
    
    PhotoBrowserManager.defaultManager.photoBrowserView.preloadingOperationDic[ @(self.model.index)] = operation;
}



@end
