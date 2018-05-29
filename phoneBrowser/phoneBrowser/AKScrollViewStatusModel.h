//
//  AKScrollViewStatusModel.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AKScrollViewStatusModel : NSObject

/**scale*/
@property(nonatomic,strong) NSNumber  * scale;

/**偏移*/
@property(nonatomic,assign) CGPoint  contentOffset ;

/**当前图片*/
@property(nonatomic,strong) UIImage  * currentPageImage;

/**url*/
@property(nonatomic,strong) NSURL *url ;

/**是否正在显示*/
@property(nonatomic,assign)BOOL isShowing;

/***/
@property(nonatomic,assign)BOOL showPopAnimation;

/**图片下标*/
@property(nonatomic,assign)BOOL index;

/**是否是gif*/
@property(nonatomic,assign)BOOL isGif;

/**gif data*/
@property(nonatomic,strong)NSData * gifData;

/**当前imageView*/
@property(nonatomic,assign) UIImageView*  currentPageImageView ;

@end
