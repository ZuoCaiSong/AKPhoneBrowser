//
//  AKLoadingView.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AKLoadingView : UIView

+ (UILabel *)showText:(NSString *)text toView:(UIView *)superView dismissAfterSecond:(NSTimeInterval)second;

@end
