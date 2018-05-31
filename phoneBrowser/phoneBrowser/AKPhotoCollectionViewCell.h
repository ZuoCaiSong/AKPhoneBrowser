//
//  AKPhotoCollectionViewCell.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AKZoomScrollView.h"

@interface AKPhotoCollectionViewCell : UICollectionViewCell

/**scrollview,用于放大缩小图片*/
@property(nonatomic,strong) AKZoomScrollView  * zoomScrollView ;

/**数据模型*/
@property(nonatomic,strong)AKScrollViewStatusModel  * model;


/**
 cell上面图片弹出的动画

 @param model 数据模型
 @param completion 完成的回调
 */
- (void)startPopAnimationWithModel:(AKScrollViewStatusModel *)model completionBlock:(void(^)(void))completion;

@end
