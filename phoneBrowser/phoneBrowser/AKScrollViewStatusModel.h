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

/**操作*/
@property(nonatomic,strong)id  operation;

/**是否正在显示*/
@property(nonatomic,assign)BOOL isShowing;

/***/
@property(nonatomic,assign)BOOL showPopAnimation;

/**图片下标*/
@property(nonatomic,assign)int index;

/**是否是gif*/
@property(nonatomic,assign)BOOL isGif;

/**gif data*/
@property(nonatomic,strong)NSData * gifData;

/**当前imageView*/
@property(nonatomic,assign) UIImageView*  currentPageImageView ;

/**图片下载完成的回调*/
@property (nonatomic , copy)void (^loadImageCompletedBlock)(AKScrollViewStatusModel *loadModel,UIImage *image, NSData *data, NSError *  error, BOOL finished, NSURL *imageURL);

@end
