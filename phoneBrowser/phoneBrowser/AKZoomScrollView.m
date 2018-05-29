//
//  AKZoomScrollView.m
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//


#import "AKZoomScrollView.h"

#import "AKLoadingView.h"

#import <FLAnimatedImageView+WebCache.h> //可直接加载gif
#import "Config.h"

#import "PhotoBrowserManager.h"

//内联函数 ,通过size,移动到中间
static inline CGRect moveSizeToCenter(CGSize size) {
    return CGRectMake((ScreenW - size.width) / 2.0, (ScreenH - size.height)/2.0, size.width, size.height);
}

//图片的最大/最小 放大倍数
static CGFloat scrollViewMinZoomScale = 1.0;
static CGFloat scrollViewMaxZoomScale = 3.0;

@interface AKZoomScrollView()<UIScrollViewDelegate,UIGestureRecognizerDelegate>

/**图片的size*/
@property(nonatomic,assign) CGSize  imageSize ;

/**原来的farme*/
@property(nonatomic,assign)CGSize oldFrame;

@property (nonatomic , strong)AKLoadingView *loadingView;

@end


@implementation AKZoomScrollView


#pragma mark - 懒加载区域
-(AKTapDetectingImageView *)imageView{
    if (!_imageView) {
        AKTapDetectingImageView *imageView  = [[AKTapDetectingImageView alloc]init];
        [self addSubview:imageView];
        _imageView = imageView;
    }
    return _imageView;
}

- (AKLoadingView *)loadingView {
    if (!_loadingView) {
        AKLoadingView *loadingView = [[AKLoadingView alloc]initWithFrame:CGRectMake(0, 0, 40, 40)];
        loadingView.frame = moveSizeToCenter(loadingView.frame.size);
        [self addSubview:loadingView];
        _loadingView = loadingView;
    }
    return _loadingView;
}

#pragma mark - 初始化本身
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.delegate = self;
        self.alwaysBounceVertical = true;
        self.showsHorizontalScrollIndicator = false;
        self.showsVerticalScrollIndicator = false;
        self.decelerationRate = UIScrollViewDecelerationRateFast; //减速快
        self.frame = CGRectMake(10, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        self.minimumZoomScale = scrollViewMinZoomScale;
        self.panGestureRecognizer.delegate = self;
        if (@available(iOS 11, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [self imageView];
    }
    return self;
}

-(UIImage *)getPlaceholdImageForModel:(AKScrollViewStatusModel *)model{
    PhotoBrowserManager * mgr = [PhotoBrowserManager defaultManager];
    UIImage *placeholdImage = nil;
    if (mgr.placeholdImageCallBackBlock) {
        placeholdImage = mgr.placeholdImageCallBackBlock([NSIndexPath indexPathForItem:model.index inSection:0]);
        if (placeholdImage==nil) {
            //使用系统的占位图
            placeholdImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"" ofType:nil]];
        }
    }else{
        placeholdImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"" ofType:nil]];
    }
    return placeholdImage;
}

#pragma mark -
-(void)setModel:(AKScrollViewStatusModel *)model{
    _model = model;
    weak_self;
    model.currentPageImageView = self.imageView;
    
    //移除imageView.layer上面的动画
    [self removePreviousFadeAnimationForLayer:self.imageView.layer];
    PhotoBrowserManager *mgr = [PhotoBrowserManager defaultManager];
    if (!model.currentPageImageView) {
        
        //1 .适配 iPhone X
        [self adjustIOS11];
        
        //2 . loading 框
        [self loadingView];
        
        //3.重新赋值
        wself.maximumZoomScale = scrollViewMinZoomScale;
        
        //4 或者占位图的的size
        CGSize size = mgr.placeholdImageSizeBlock ? mgr.placeholdImageSizeBlock([self getPlaceholdImageForModel:model], [NSIndexPath indexPathForItem:model.index inSection:0]) : CGSizeZero;
        if (!CGSizeEqualToSize(size, CGSizeZero)) { //不为0
            //不明白,为何要动态修改frame
            self.imageView.frame = moveSizeToCenter(size);
        }else{
            [self resetScrollViewStatusWithImage:model.currentPageImageView];
            
        }
        
    }
    
}

#pragma mark - 适配ios11 的inset
-(void)adjustIOS11{
    /*适配 iPhone X*/
    if(@available(iOS 11.0, *)){
        if (self.contentInsetAdjustmentBehavior == UIScrollViewContentInsetAdjustmentAutomatic) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
}

#pragma mark - 移除一个CAlayer 动画

- (void)removePreviousFadeAnimationForLayer:(CALayer *)layer{
    [layer removeAnimationForKey:@"ak.fade"];
}


#pragma mark - 重置scrollviewStatus
-(void)resetScrollViewStatusWithImage:(UIImage *)image {
    
    self.zoomScale = scrollViewMinZoomScale;
    
    self.imageView.frame = CGRectMake(0, 0, self.frame.size.width, 0);
    //1 . 图片宽高比 > 屏幕宽高比
    if (image.size.height / image.size.width > self.height /  self.width) {
        CGFloat height = floor(image.size.height / image.size.width * self.width);
        self.imageView.height = height;
    }else{// 图片宽高比 < 屏幕宽高比
        CGFloat height = image.size.height / image.size.width * self.width;
        self.imageView.height = floor(height);
        self.imageView.centerY = self.height / 2;
    }
    
    if (self.imageView.height > self.height && self.imageView.height - self.height <= 1) {
        self.imageView.height = self.height;
    }
    
    self.contentSize = CGSizeMake(self.width, MAX(self.imageView.height, self.height));
    [self setContentOffset:CGPointZero];
    
    self.alwaysBounceVertical = (self.imageView.height > self.height);
    
    if (self.imageView.contentMode != UIViewContentModeScaleToFill) {
        self.imageView.contentMode = UIViewContentModeScaleToFill;
        self.imageView.clipsToBounds = false;
    }
}


-(void)handleSingleTap:(CGPoint)touchPoint{
    
}

@end
