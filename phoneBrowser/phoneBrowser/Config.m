//
//  Config.m
//  phoneBrowser
//
//  Created by 阿K on 2018/4/24.
//  Copyright © 2018年 阿K. All rights reserved.
//

#ifndef Config_h
#define Config_h

#import <Foundation/Foundation.h>

#import "Config.h"

/**通知名常量*/

/**将要消失的通知*/
NSString * const AKImageViewWillDismissNoti = @"AKImageViewWillDismissNoti";

/**已经消失的通知*/
NSString * const AKImageViewDidDismissNoti = @"AKImageViewDidDismissNoti";

NSString * const AKGifImageDownloadFinishedNoti = @"AKGifImageDownloadFinishedNoti";

NSString * const AKLinkageInfoStyleKey = @"ak_style";
NSString * const AKLinKageInfoReuseIdentifierKey = @"ak_reuseIdentifier";

#endif
