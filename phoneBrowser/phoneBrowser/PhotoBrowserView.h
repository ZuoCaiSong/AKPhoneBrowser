//
//  PhotoBrowserView.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoBrowserView : UIWindow

@property (nonatomic , weak)UIPageControl *pageControl;

/**预加载里面的数据模型键值对为 index: operation*/
@property (nonatomic , strong)NSMutableDictionary <NSNumber*,NSOperation*>*preloadingOperationDic;

/**
 展示图片浏览

 @param objs 数组objs 元素要么全是NSURL的链接,要么全是本地的uiimage
 @param index selectIndex
 */
- (void)showImageViewsWithURLsOrImages:(NSMutableArray *)objs andSelectedIndex:(NSInteger)index;


@end
