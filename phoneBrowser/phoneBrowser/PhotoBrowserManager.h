//
//  PhotoBrowserManager.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoBrowserManager : NSObject

/** 当前选中的页 */
@property (nonatomic , assign)NSInteger currentPage;

/**每张正在加载图片的占位图*/
@property(nonatomic,copy,readonly) UIImage *(^ placeholdImageCallBackBlock)(NSIndexPath * indexPath) ;

/**每张正在加载图片的占位图的大小*/
@property(nonatomic,copy,readonly) CGSize (^ placeholdImageSizeBlock)(UIImage * Image,NSIndexPath * indexPath) ;

/**
 返回一个单利
 @return 单利
 */
+ (instancetype)defaultManager;

@end
