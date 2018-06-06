//
//  AKZoomScrollView.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

/**加载在cell里面,用来存放每一张图片*/

#import <UIKit/UIKit.h>

#import "AKTapDetectingImageView.h" //imageview

#import "AKScrollViewStatusModel.h" //图片模型

@interface AKZoomScrollView : UIScrollView



/**展示的图片*/
@property(nonatomic,strong) AKTapDetectingImageView *  imageView;

/**每张图片所对应的模型*/
@property(nonatomic,strong) AKScrollViewStatusModel *  model;

/**当前scrollview的图片是否正在移动*/
@property(nonatomic,assign ) BOOL  imageViewIsMoving;


/**
 单击图片时的手势方法

 @param touchPoint 触摸
 */
-(void)handleSingleTap:(CGPoint)touchPoint;


/**
 双击图片时的手势方法
 
 @param touchPoint 触摸
 */
-(void)handleDoubleTap:(CGPoint)touchPoint;

/**将图片盖在手机最外层*/
- (void)startPopAnimationWithModel:(AKScrollViewStatusModel *)model completionBlock:(void(^)(void))completion;
@end
