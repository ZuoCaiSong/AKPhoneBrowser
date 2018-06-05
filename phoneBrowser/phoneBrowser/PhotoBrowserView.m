//
//  PhotoBrowserView.m
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "PhotoBrowserView.h"

#import "PhotoBrowserManager.h"

#import "AKPhotoCollectionViewCell.h" //控制器的cell

#import "Config.h" //配置文件

#import <SDWebImage/SDImageCache.h> //缓存
#import <SDWebImage/SDWebImageManager.h> //管理

/**item的左右多出10,用作间隔*/
static CGFloat const itemSpace = 20.0;

@interface PhotoBrowserView()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

/**用于图片横向滚动的容器*/
@property (nonatomic , weak)UICollectionView *collectionView;

/**collectionView的数据源*/
@property (nonatomic , strong)NSMutableArray *dataArr;

@property (nonatomic , strong)NSMutableArray <AKScrollViewStatusModel *> *models;

@property (nonatomic , assign)BOOL isShowing;

@property (nonatomic , assign)BOOL navBarStatusHidden;

/**拖拽时,手势开始是,手指在屏幕中的位置坐标*/
@property (nonatomic , assign)CGPoint startPoint;

/**图片的当前缩放比例*/
@property (nonatomic , assign)CGFloat zoomScale;

@property (nonatomic , assign)CGPoint startCenter;

@property (nonatomic , strong)NSMutableDictionary *loadingImageModelDic;

/**预加载里面的数据模型键值对为 index: model*/
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
        [PhotoBrowserManager defaultManager].currentCollectionView = self.collectionView;
        
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
/**将要dismiss时候调用*/
-(void)removePageControl{
    [UIView animateWithDuration:0.25 animations:^{
        self.pageControl.alpha = 0;
    }completion:^(BOOL finished) {
        [self.pageControl removeFromSuperview];
    }];
    if (![PhotoBrowserManager defaultManager].needPreloading) { return;}
    
    //取消当前所有的下载任务
    [self.loadingImageModelDic.allValues enumerateObjectsUsingBlock:^(AKScrollViewStatusModel * model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (model.operation) {
            [model.operation cancel];
        }
    }];
}

#pragma mark - 图片的加载,通过urls/ images 显示
- (void)showImageViewsWithURLsOrImages:(NSMutableArray *)objs andSelectedIndex:(NSInteger)index{
    _dataArr = objs;
    if (_pageControl) {
        [_pageControl removeFromSuperview];
    }
    self.pageControl.bottom = ScreenH - 50;
    self.pageControl.hidden = (objs.count == 1);
    //models 清楚模型, 初始化
    [self.models removeAllObjects];
    //重新构建 model
    for(int i = 0 ; i < _dataArr.count; i++) {
        AKScrollViewStatusModel *model = [[AKScrollViewStatusModel alloc]init];
        model.showPopAnimation = (i==index); //是否当前需要pop显示出来
        model.isShowing = (i==index);
        if ([objs[i] isKindOfClass:[NSURL class]]) {
            model.url = objs[i];
        }else if ([objs[i] isKindOfClass:[UIImage class]]){
            model.currentPageImage = objs[i];
        }else{
            NSAssert(false,@"objs 数据类型不匹配");
        }
        model.index = i;
        [self.models addObject:model];
    }
    self.collectionView.alwaysBounceHorizontal = !(objs.count == 1); //一张图片的时候不进行 Bounce
    [self.collectionView reloadData];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:false];
}


#pragma mark - collectionView的数据源&代理
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_dataArr) {
        return _dataArr.count;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *ID = NSStringFromClass([AKPhotoCollectionViewCell class]);
    AKPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ID forIndexPath:indexPath];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(ScreenW + itemSpace, ScreenH);
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(AKPhotoCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    weak_self;
    //获取数据模型
    AKScrollViewStatusModel * model = self.models[indexPath.row];
    
    model.currentPageImage = model.currentPageImage ?: [self getCacheImageForModel:model];
    //需要展示动画的话,展示动画
    if(model.showPopAnimation){
        [cell startPopAnimationWithModel:model completionBlock:^{ //
            wself.isShowing = true;
            model.showPopAnimation = false;
            //递归调用一次
            [wself collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
        }];
    }
    if (wself.isShowing == false) { return;}
    //赋值模型
    cell.model = model;
    
    if (model.currentPageImage && model.currentPageImage.images.count >0) {
        [self scrollViewDidScroll:collectionView];
    }
    
    if ([self.dataArr.firstObject isKindOfClass:[UIImage class]]) return;
    
    //预加载
   // [self preloadImageWithModel:model];
}



#pragma mark - 预加载图片
/**只提前加载前后两张图片*/
-(void)preloadImageWithModel:(AKScrollViewStatusModel *)model{
    weak_self;
    //不需要预加载直接return
    if (![PhotoBrowserManager defaultManager].needPreloading) return;
    //异步并发队列
    dispatch_async(self.preloadingQueue, ^{
        int leftIndex = model.index -1>=0 ?  model.index -1 : 0;
        int rightIndex = model.index + 1 < wself.models.count ? model.index+1 :  (int)(wself.models.count - 1) ;
        
        //wself.loadingImageModels 新计算出的需要加载的 -- > 如果个原来的没有重合的 --> 取消
        [wself.preloadingModelDic removeAllObjects];
        wself.preloadingModelDic[@(leftIndex)] = @1;
        wself.preloadingModelDic[@(model.index)] = @1;
        wself.preloadingModelDic[@(rightIndex)] = @1;
        
        for (NSNumber * indexNum in wself.preloadingModelDic.allKeys) {
            AKScrollViewStatusModel * loadingModel = wself.loadingImageModelDic[indexNum];
            if (loadingModel.operation) {
                [loadingModel.operation cancel];
                loadingModel.operation = nil;
            }
        }
        [wself.loadingImageModelDic removeAllObjects];
        
        for (int i = leftIndex; i<=rightIndex; i++) {
            AKScrollViewStatusModel * loadingModel = self.models[i];
            wself.loadingImageModelDic[@(i)] = loadingModel;
            if (model.index == i) continue;
            //预加载部分
            AKScrollViewStatusModel *preloadingModel = wself.models[i];
            preloadingModel.currentPageImage = preloadingModel.currentPageImage ?:[wself getCacheImageForModel:preloadingModel];
            if (preloadingModel.currentPageImage) continue;
            [preloadingModel downloadImage];
        }
    });
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat pageWidth = self.collectionView.width;
    int page = floor((self.collectionView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    [self refreshStatusWithPage:page];
    self.pageControl.currentPage = page;
    [PhotoBrowserManager defaultManager].currentPage = page;
    
    AKPhotoCollectionViewCell *cell = (AKPhotoCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:page inSection:0]];
    if (![scrollView isKindOfClass:[UIScrollView class]]) {
        PhotoBrowserManager.defaultManager.currentShowImageView = nil;
    }
       PhotoBrowserManager.defaultManager.currentShowImageView = cell.zoomScrollView.imageView;
    
}

- (void)refreshStatusWithPage:(int)page {
    if (page == self.pageControl.currentPage ) {
        return;
    }
    [self changeModelOfCellInRow:page];
}

#pragma mark - 修改cell子控件的状态
-(void)changeModelOfCellInRow:(int)row{
    for (AKScrollViewStatusModel *model in self.models) {
        model.isShowing = NO;
    }
    if (row >= 0 && row < self.models.count) {
        AKScrollViewStatusModel *model = self.models[row];
        model.isShowing = YES;
    }
}

#pragma mark - 根据URL获取缓存的图片

- (UIImage *)getCacheImageForModel:(AKScrollViewStatusModel *)model {
    
    SDImageCache * imageCache = [SDImageCache sharedImageCache];
    
    //1 获取图片缓存时对应的key
    NSString*cacheImageKey = [[SDWebImageManager sharedManager]cacheKeyForURL:model.url];
    
    //2 获取缓存的图片
    return [imageCache  imageFromCacheForKey:cacheImageKey];
}


#pragma mark - dealloc
- (void)dealloc {
    NSLog(@"%@ is dealloc",self.class);
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}


@end
