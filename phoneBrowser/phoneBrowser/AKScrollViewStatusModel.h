//
//  AKScrollViewStatusModel.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AKScrollViewStatusModel : NSObject

/*******
 以下5个属性在构建模型的时候会初始化 在PhotoBrowserView.m文件的 showImageViewsWithURLsOrImages方法里面进行赋值
 加载本地图片的时候,url是没有值的,currentPageImage会被立即赋值. 网络图片时 url才会被赋值
 ******/

/**pic 对应的 url*/
@property(nonatomic,strong) NSURL *url ;

/**是否正在显示*/
@property(nonatomic,assign)BOOL isShowing;

/**图片下标*/
@property(nonatomic,assign)int index;

/***/
@property(nonatomic,assign)BOOL showPopAnimation;

/**当前图片*/
@property(nonatomic,strong) UIImage  * currentPageImage;


/*****以下两个属性在用户图片进行放大,拖拽是进行重新赋值,默认偏移为0 ,scale默认为1 ******/
/**scale,默认为1*/
@property(nonatomic,strong) NSNumber  * scale;

/**偏移*/
@property(nonatomic,assign) CGPoint  contentOffset ;



/**操作, 有值表示对应的图片正在下载,没值可能是下载完成,或者还未开始下载*/
@property(nonatomic,strong)id  operation;


///**是否是gif*/
//@property(nonatomic,assign)BOOL isGif;
//
///**gif data*/
//@property(nonatomic,strong)NSData * gifData;

/**图片下载完成的回调*/
@property (nonatomic , copy)void (^loadImageCompletedBlock)(AKScrollViewStatusModel *loadModel,UIImage *image, NSData *data, NSError *  error, BOOL finished, NSURL *imageURL);


/**开始下载图片*/
-(void)downloadImage;

/**
 图片下载完成的回调

 @param completedBlock 图片下载完成的回调
 */
- (void)loadImageWithCompletedBlock:(void (^)(AKScrollViewStatusModel *loadModel,UIImage *image, NSData *data, NSError *  error, BOOL finished, NSURL *imageURL))completedBlock;

@end
