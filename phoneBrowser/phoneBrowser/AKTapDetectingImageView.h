//
//  AKTapDetectingImageView.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <FLAnimatedImage/FLAnimatedImage.h>

@class AKScrollViewStatusModel;

@interface AKTapDetectingImageView : FLAnimatedImageView


@property(nonatomic,strong)AKScrollViewStatusModel *model;

/**图片下载完成的回调*/
@property (nonatomic , copy)void (^loadImageCompletedBlock)(AKScrollViewStatusModel *loadModel,UIImage *image, NSData *data, NSError *  error, BOOL finished, NSURL *imageURL);


/**开始下载图片*/
-(void)downloadImage;

/**
 图片下载完成的回调
 
 @param completedBlock 图片下载完成的回调
 */
- (void)loadImageWithCompletedBlock:(void (^)(AKScrollViewStatusModel *loadModel,UIImage *image, NSData *data, NSError *  error, BOOL finished, NSURL *imageURL))completedBlock;

@end
