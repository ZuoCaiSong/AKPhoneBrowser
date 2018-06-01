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
@property(nonatomic,assign)CGRect oldFrame;

/***/
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
        loadingView.frame = moveSizeToCenter(loadingView.frame.size);//居中显示
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
        
        //2 . add loading 框
        [self loadingView];
        
        //3.重新赋值
        wself.maximumZoomScale = scrollViewMinZoomScale;
        
        //4 或者占位图的的size
        CGSize size = mgr.placeholdImageSizeBlock ? mgr.placeholdImageSizeBlock([self getPlaceholdImageForModel:model], [NSIndexPath indexPathForItem:model.index inSection:0]) : CGSizeZero;
        if (!CGSizeEqualToSize(size, CGSizeZero)) { //不为0
            //不明白,为何要动态修改frame
            self.imageView.frame = moveSizeToCenter(size);
        }else{
            [self resetScrollViewStatusWithImage:[self getPlaceholdImageForModel:model]];
            
        }
        
        self.imageView.image = [self getPlaceholdImageForModel:model];
        
        //通过模型开始加载数据
        
        [model loadImageWithCompletedBlock:^(AKScrollViewStatusModel *loadModel, UIImage *image, NSData *data, NSError *error, BOOL finished, NSURL *imageURL) { //图片下载完成的回调
            //1.移除loading图
            [wself.loadingView removeFromSuperview];
            wself.maximumZoomScale = scrollViewMaxZoomScale;
            if (error) {
                image = mgr.errorImage;
            }
            model.currentPageImage = image;
            
            //下载完成之后,只有当前cell正在展示 ---> 刷新
            NSArray * cells = [mgr.currentCollectionView visibleCells];
            for (id obj in cells) {
                AKScrollViewStatusModel *visibleModel = [obj valueForKey:@"model"];
                if (model.index == visibleModel.index) {
                    [wself reloadCellDataWithModel:model andImage:image andImageData:data];
                }
            }
        }];
    }else{ //已经存在了
        if (_loadingView) {
            [_loadingView removeFromSuperview];
        }
        [self resetScrollViewStatusWithImage:model.currentPageImage];
        /**
         when lowGifMemory = NO,if not clear this image ,gif image may have some thing wrong
         */
        self.imageView.image = nil;
        self.imageView.image = model.currentPageImage;
        self.maximumZoomScale = scrollViewMaxZoomScale;
    }
    self.zoomScale = model.scale.floatValue;
    self.contentOffset = model.contentOffset;
    
}

#pragma mark - cho
-(void) reloadCellDataWithModel:(AKScrollViewStatusModel *)model andImage:(UIImage*)image andImageData:(NSData *)data{
    
    PhotoBrowserManager * mgr = [PhotoBrowserManager defaultManager];
    self.imageView.image = model.currentPageImage;
    
    //重置scrollview的状态
    [self resetScrollViewStatusWithImage:model.currentPageImage];
    
    //获取展位图的大小
    CGSize size = mgr.placeholdImageSizeBlock ? mgr.placeholdImageSizeBlock([self getPlaceholdImageForModel:model], [NSIndexPath indexPathForItem:model.index inSection:0]) : CGSizeZero;
    
    if(!CGSizeEqualToSize(size, CGSizeZero)){ //不为0
        CGRect imageViewFrame = self.imageView.frame;
        self.imageView.frame = moveSizeToCenter(size);
        [UIView animateWithDuration:0.25 animations:^{
            self.imageView.frame = imageViewFrame;
        }];
    }else{ //占位图size 为 0
        [self addFadeAnimationWithDuration:0.25 curve:UIViewAnimationCurveLinear ForLayer:self.imageView.layer];
    }

}

#pragma mark - 开始pop动画
- (void)startPopAnimationWithModel:(AKScrollViewStatusModel *)model completionBlock:(void (^)(void))completion{
    UIImage * currentImage = model.currentPageImage;
    _model = model;
    if(!currentImage){
        currentImage = [self getPlaceholdImageForModel:model];
    }
    [self showPopAnimationWithImage:currentImage WithCompletionBlock:completion];
}

- (void)showPopAnimationWithImage:(UIImage *)image WithCompletionBlock:(void (^)(void))completion {
    weak_self;
    PhotoBrowserManager *mgr = [PhotoBrowserManager defaultManager];
    //读取图片最开始的frame值,例如九宫格中某一张图片的frame
    CGRect animationViewFrame = [mgr.frames[mgr.currentPage]  CGRectValue];
    CGRect rect = [mgr.imageViewSuperView convertRect: animationViewFrame toView:[UIApplication sharedApplication].keyWindow];
    self.oldFrame = rect;
    CGRect photoImageViewFrame;
    //获取展位图的size
    CGSize size = mgr.placeholdImageSizeBlock ? mgr.placeholdImageSizeBlock(image, [NSIndexPath indexPathForItem:self.model.index inSection:0]) : CGSizeZero;
    if (!CGSizeEqualToSize(size, CGSizeZero) && !self.model.currentPageImage) {//展位图的size不为0
        photoImageViewFrame = moveSizeToCenter(size);
    }else {
        [self resetScrollViewStatusWithImage:image];
        photoImageViewFrame = self.imageView.frame;
    }
    //正在移动的状态
    self.imageViewIsMoving = true;
    self.imageView.frame = self.oldFrame;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
        wself.imageView.frame = photoImageViewFrame; //可以理解为一个变大的动画
    } completion:^(BOOL finished) {
        wself.imageViewIsMoving = false;
        [wself layoutSubviews]; // sometime need layout
        if (completion) {
            completion();
        }
    }];
    
    // if not clear this image ,gif image may have some thing wrong
    self.imageView.image = nil;
    self.imageView.image = image;
    [self setNeedsLayout];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    //图片在移动的时候停止居中布局
    if(self.imageViewIsMoving == true)return;
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.imageView.frame;
   
    // x
    frameToCenter.origin.x = (frameToCenter.size.width < boundsSize.width)? (boundsSize.width - frameToCenter.size.width)/2.0 : 0;
    
    // y
    frameToCenter.origin.y = (frameToCenter.size.height < boundsSize.height)? (boundsSize.height - frameToCenter.size.height)/2.0 : 0;
  
    // frame
    self.imageView.frame =  !CGRectEqualToRect(self.imageView.frame, frameToCenter) ? frameToCenter :self.imageView.frame ;
}



#pragma mark - 动画

- (void)addFadeAnimationWithDuration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve ForLayer:(CALayer *)layer{
    if(duration <= 0) return;
    
    NSString *mediaFuncton;
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            mediaFuncton = kCAMediaTimingFunctionEaseInEaseOut;
            break;
        case UIViewAnimationCurveEaseIn:
            mediaFuncton = kCAMediaTimingFunctionEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            mediaFuncton = kCAMediaTimingFunctionEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            mediaFuncton = kCAMediaTimingFunctionLinear;
            break;
        default:
            mediaFuncton = kCAMediaTimingFunctionLinear;
            break;
    }
    CATransition * transition = [CATransition animation];
    transition.duration = duration;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:mediaFuncton];
    transition.type = kCATransitionFade;
    [layer addAnimation:transition forKey:@"ak.fade"];
}


/**
  移除一个CAlayer动画

 @param layer 移除layer上与之对应的key动画
 */
- (void)removePreviousFadeAnimationForLayer:(CALayer *)layer{
    [layer removeAnimationForKey:@"ak.fade"];
}


#pragma mark - 重置scrollviewStatus
-(void)resetScrollViewStatusWithImage:(UIImage *)image {
    
    //将缩放设置为初始化状态
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

#pragma mark - scrollView delegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView{
    
    if (self.model.isShowing == false) {
        return;
    }
    self.model.scale = @(scrollView.zoomScale);
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
}

-(void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale{
    if (scrollView.minimumZoomScale != scale) {
        return;
    }
    [self setZoomScale:self.minimumZoomScale animated:true];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (self.model.isShowing == false) {
        return;
    }
    self.model.contentOffset = scrollView.contentOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (self.imageView.height> ScreenW) {
        [[PhotoBrowserManager defaultManager].currentCollectionView
         scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.model.index inSection:0]
         atScrollPosition:UICollectionViewScrollPositionNone animated:true];
    }
}

#pragma mark - imageView 点击事件的的处理方法


/**
 单击事件 ,将图片remove掉

 @param touchPoint 手指触碰的点
 */
-(void)handleSingleTap:(CGPoint)touchPoint{
    //1.先判定是否有loading视图
    if(_loadingView){
        [_loadingView removeFromSuperview];
    }
    
    if([[PhotoBrowserManager defaultManager].imageViewSuperView isKindOfClass:[UICollectionView class]]){
        [self configCollectionViewAnimationStyle];
    }
    
    //2.发布一个将要dismiss的通知
    [[NSNotificationCenter defaultCenter]postNotificationName:AKImageViewWillDismissNoti object:nil];
    PhotoBrowserManager *mgr = [PhotoBrowserManager defaultManager];
    
    CGRect currentViewFrame = [mgr.frames[mgr.currentPage] CGRectValue];
    
    //3 currentViewFrame的值在以keyWindow作为参考时 对应的frame
    self.oldFrame = [mgr.imageViewSuperView convertRect:currentViewFrame toView:[UIApplication sharedApplication].keyWindow];
    
    //4 正在moveing
    UIImageView * dismissView = self.imageView;
    self.imageViewIsMoving = true;
    weak_self;
    [UIView animateWithDuration:0.2 animations:^{
        wself.zoomScale = scrollViewMinZoomScale;
        wself.contentOffset = CGPointZero;
        dismissView.frame = wself.oldFrame; //关键是这个,看上去图片缩小,图片回到了对应的cell图片上面
        dismissView.contentMode = UIViewContentModeScaleAspectFill;
        dismissView.clipsToBounds = true;
        if (wself.model.currentPageImage.images.count > 0) {
            dismissView.image = wself.model.currentPageImage;
        }
        //改变背景颜色
        [PhotoBrowserManager defaultManager].currentCollectionView.superview.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        //动画完成之后,在进行一个动画
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            wself.imageView.alpha = 0;
        } completion:^(BOOL finished) {
            [dismissView removeFromSuperview];
            [wself removeFromSuperview];
            //已经dismiss的通知
            [[NSNotificationCenter defaultCenter]postNotificationName:AKImageViewDidDismissNoti object:nil];
        }];
    }];
}

/**
 实现逻辑: 处于放大状态则双击复原,否则则放大
 双击事件 ,将图片remove掉
 
 @param touchPoint 手指触碰的点
 
 */
-(void)handleDoubleTap:(CGPoint)touchPoint{
    if(self.maximumZoomScale == self.minimumZoomScale){return;}
    
    if (self.zoomScale != self.minimumZoomScale) { //有被放大,则复原
        [self setZoomScale:self.minimumZoomScale animated:true];
    }else{ //初始状态,  则进行放大
        CGFloat newZoomScale = self.maximumZoomScale;
        CGFloat width = self.width / newZoomScale;
        CGFloat height = self.height / newZoomScale;
        //将内容视图缩放到指定的Rect中
        [self zoomToRect:CGRectMake(touchPoint.x - width/2, touchPoint.y - height/2, width, height) animated:true];
    }
}


#pragma mark - collectionView 特有的动画
- (void)configCollectionViewAnimationStyle{
    //1 取出关联数据
    NSDictionary * info = [PhotoBrowserManager defaultManager].linkageInfo;
    NSString * reuseIdentifier = info[AKLinKageInfoReuseIdentifierKey];
    
    NSAssert(!reuseIdentifier, @"请设置传入collectionViewCell的reuseIdentifier");
     
    //2 获取style
    NSUInteger style = info[AKLinkageInfoStyleKey] ? UICollectionViewScrollPositionCenteredHorizontally : [info[AKLinkageInfoStyleKey] unsignedIntValue];
    
    UICollectionView *collectionView = (UICollectionView *)[PhotoBrowserManager defaultManager].imageViewSuperView;
    
    NSIndexPath * index = [NSIndexPath indexPathForItem:[PhotoBrowserManager defaultManager].currentPage inSection:0];
    [collectionView scrollToItemAtIndexPath:index atScrollPosition:style animated:false];
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:index];
    NSValue *value = [NSValue valueWithCGRect:cell.frame];
    
    //重新给cell赋值
    [[PhotoBrowserManager defaultManager].frames replaceObjectAtIndex:index.row withObject:value];
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
@end
