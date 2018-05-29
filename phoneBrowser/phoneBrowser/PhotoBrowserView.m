//
//  PhotoBrowserView.m
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "PhotoBrowserView.h"

#import "AKPhotoCollectionViewCell.h" //控制器的cell

#import "Config.h" //配置文件

/**item的左右多出10,用作间隔*/
static CGFloat const itemSpace = 20.0;

@interface PhotoBrowserView()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

/**用于图片横向滚动的容器*/
@property (nonatomic , weak)UICollectionView *collectionView;

@property (nonatomic , strong)NSMutableArray *dataArr;

@property (nonatomic , strong)NSMutableArray *models;

@property (nonatomic , assign)BOOL isShowing;

@property (nonatomic , assign)BOOL navBarStatusHidden;

/**拖拽时,手势开始是,手指在屏幕中的位置坐标*/
@property (nonatomic , assign)CGPoint startPoint;

/**图片的当前缩放比例*/
@property (nonatomic , assign)CGFloat zoomScale;

@property (nonatomic , assign)CGPoint startCenter;

@property (nonatomic , strong)NSMutableDictionary *loadingImageModelDic;
@property (nonatomic , strong)NSMutableDictionary *preloadingModelDic;

/**预加载队列*/
@property (strong, nonatomic) dispatch_queue_t preloadingQueue;

@end

@implementation PhotoBrowserView

#pragma mark - 属性懒加载区域
-(NSMutableArray *)models{
    if (!_models) {
        _models = [NSMutableArray array];
    }
    return _models;
}

-(NSMutableDictionary *)preloadingModelDic{
    if (!_loadingImageModelDic) {
        _loadingImageModelDic = [NSMutableDictionary dictionary];
    }
    return _loadingImageModelDic;
}

- (NSMutableDictionary *)loadingImageModelDic {
    if (!_loadingImageModelDic) {
        _loadingImageModelDic = [[NSMutableDictionary alloc]init];
    }
    return _loadingImageModelDic;
}

-(UIPageControl *)pageControl{
    if (!_pageControl) {
        UIPageControl * pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(0, 0,ScreenW ,10)];
        pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        pageControl.pageIndicatorTintColor = [UIColor grayColor];
        pageControl.numberOfPages = self.dataArr.count;
        [self addSubview:pageControl];
        _pageControl = pageControl;
    }
    return _pageControl;
}

//懒加载collectionView
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.minimumLineSpacing = 0;
        // there page sapce is equal to 20
        UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(-itemSpace / 2.0, 0, ScreenW + itemSpace, ScreenH) collectionViewLayout:flowLayout];
        [self addSubview:collectionView];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.pagingEnabled = YES;
        collectionView.alwaysBounceVertical = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.backgroundColor = [UIColor clearColor]; //背景透明
        [self collectionViewRegisterCellWithCollectionView:collectionView];
        _collectionView = collectionView;
    }
    return _collectionView;
}

#pragma mark - 注册cell
-(void)collectionViewRegisterCellWithCollectionView:(UICollectionView *)collentionView {
    
    NSString * cellId = NSStringFromClass([AKPhotoCollectionViewCell class]);
    
    [collentionView registerClass:[AKPhotoCollectionViewCell class] forCellWithReuseIdentifier:cellId];

}

#pragma mark - 视图的初始化区域
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelAlert; //显示时,级别高,在上层
        self.hidden = false;
        self.backgroundColor = [UIColor blackColor];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(scrollViewDidScroll:) name:AKGifImageDownloadFinishedNoti object:nil];
        //图片将要消失的时候
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(removePageControl) name:AKImageViewDidDismissNoti object:nil];
        //添加一个pan手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
        [self addGestureRecognizer:pan];
        //[PhotoBrowserManager defaultManager].currentCollectionView = self.collectionView;
        
        //预加载的串行队列
        _preloadingQueue = dispatch_queue_create("ak.photoBrowser", DISPATCH_QUEUE_SERIAL);
        
        //标志位
        _isShowing = NO;
    }
    return self;
}

#pragma mark - 拖拽手势方法
-(void)didPan:(UIPanGestureRecognizer*)pan{
    
    //获取到的是手指点击屏幕实时的坐标点
    CGPoint location = [pan locationInView:self];
    
    //获取到的是手指移动后，在相对坐标中的偏移量(基于View上一次的位置)
    CGPoint point = [pan translationInView:self];
    
    //获取当前的cell
    AKPhotoCollectionViewCell * cell = (AKPhotoCollectionViewCell*) [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.pageControl.currentPage inSection:0]];
    //判断状态
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: //手势开始
            //1.记录开始的坐标
            self.startPoint = location;
            self.tag = 0;
            //2获取当前图片的放大比例
            self.zoomScale = cell.zoomScrollView.zoomScale;
            //3.开始时,获取图片的中心位置,取消时,方便Image位置的还原
            self.startCenter = cell.zoomScrollView.imageView.center;
//            self.navBarStatusHidden = [LBPhotoBrowserManager defaultManager].navigationBar.hidden;
            break;
         case UIGestureRecognizerStateChanged: //手势改变时
            if(location.y - self.startPoint.y < 0 && self.tag == 0){ //往上拖拽,直接return
                return;
            }
            //当前scrollView正则移动
            cell.zoomScrollView.imageViewIsMoving = true;
            //移动的百分比 移动距离 / 整个屏幕
            double percent = 1 - fabs(point.y) / self.frame.size.height;
            //百分比不低于0.3
            double scalePercent = MAX(percent, 0.3);
            //
            if (location.y - self.startPoint.y < 0) {
                scalePercent = 1.0 * self.zoomScale;
            }else{
                scalePercent = scalePercent *self.zoomScale;
            }
            //动画
            // 先缩小
            CGAffineTransform  scale = CGAffineTransformMakeScale(scalePercent, scalePercent);
            cell.zoomScrollView.imageView.transform = scale;
            // 在移动
            cell.zoomScrollView.imageView.center = CGPointMake(self.startCenter.x + point.x, self.startCenter.y + point.y);
            //更改背景颜色
            if(scalePercent / _zoomScale<0.001){
                self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];

            }else{
                self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:scalePercent / _zoomScale];
            }
            self.tag = 1;
            //            [LBPhotoBrowserManager defaultManager].navigationBar.hidden = YES;
            break;
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateFailed:
            if (point.y > 100) { //拖过的距离大于100 就直接把图片浏览器dismiss
                [self dismissFromCell:cell];
            }else{ //取消消失
                [self cancelFromCell:cell];
            }
        default:
            break;
    }
}

#pragma mark - 图片浏览器 消失
-(void)dismissFromCell:(AKPhotoCollectionViewCell *)cell{
    [cell.zoomScrollView handleSingleTap:CGPointZero];
  //  [LBPhotoBrowserManager defaultManager].navigationBar.hidden = YES;

}

#pragma mark - 取消拖拽,图片还原
- (void)cancelFromCell:(AKPhotoCollectionViewCell *)cell {
    weak_self;
    CGAffineTransform scale = CGAffineTransformMakeScale(_zoomScale, _zoomScale);
    [UIView animateWithDuration:0.25 animations:^{
        cell.zoomScrollView.imageView.transform = scale;
        wself.backgroundColor = [UIColor blackColor];
    } completion:^(BOOL finished) {
        cell.zoomScrollView.imageViewIsMoving = false;
        [cell.zoomScrollView layoutSubviews];
//        [LBPhotoBrowserManager defaultManager].navigationBar.hidden = self.navBarStatusHidden;
    }];
}

#pragma mark - 通知方法
-(void)removePageControl{
    
}




@end
