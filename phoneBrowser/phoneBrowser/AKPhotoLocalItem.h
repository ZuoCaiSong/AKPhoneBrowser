//
//  AKPhotoLocalItem.h
//  phoneBrowser
//
//  Created by LEO on 2018/6/4.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AKPhotoLocalItem : NSObject


/**
 本地图片
 */
@property (nonatomic , strong)UIImage *localImage;

/**
 每张图片对应iamgeView的frame值
 */
@property (nonatomic , assign)CGRect frame;



/**
 初始化构建方法

 @param image image
 @param frame frame值
 @return 返回一个local实例
 */
- (instancetype)initWithImage:(UIImage *)image frame:(CGRect)frame;


@end
