//
//  Config.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#ifndef Config_h
#define Config_h

#import <UIKit/UIKit.h>

#import "UIView+LBFrame.h"

#define ScreenW  [UIScreen mainScreen].bounds.size.width
#define ScreenH  [UIScreen mainScreen].bounds.size.height

/**通知名常量*/

UIKIT_EXTERN NSString * const AKImageViewWillDismissNoti ;
UIKIT_EXTERN NSString * const AKImageViewDidDismissNoti ;
UIKIT_EXTERN NSString * const AKGifImageDownloadFinishedNoti;

UIKIT_EXTERN  NSString * const AKLinkageInfoStyleKey ;
UIKIT_EXTERN  NSString * const AKLinKageInfoReuseIdentifierKey;

/**一个弱引用对象*/
#define weak_self  __weak typeof(self) wself = self

#endif /* Header_h */
