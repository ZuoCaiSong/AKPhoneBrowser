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

#import "AKPhotoTool.h"

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

/**拖拽时,手势开始时,手指在屏幕中的位置坐标*/
@property (nonatomic , assign)CGPoint startPoint;

/**图片的当前缩放比例*/
@property (nonatomic , assign)CGFloat zoomScale;

/**记录刚开始pan手势时,图片的center*/
@property (nonatomic , assign)CGPoint startCenter;


@end

@implementation PhotoBrowserView

#pragma mark - 属性懒加载区域
-(NSMutableArray *)models{
    if (!_models) {
        _models = [NSMutableArray array];
    }
    return _models;
}


-(NSMutableDictionary *)preloadingOperationDic{
    if (!_preloadingOperationDic) {
        _preloadingOperationDic = [NSMutableDictionary dictionary];
    }
    return _preloadingOperationDic;
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
    [self.preloadingOperationDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSOperation * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancel];
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
    cell.model = model;
    
    model.currentPageImage = model.currentPageImage ?: [AKPhotoTool getCacheImageForUrl:model.url];
    //需要展示动画的话,展示动画
    if(model.showPopAnimation){
        [cell startPopAnimationWithModel:model completionBlock:^{ //
            wself.isShowing = true;
            model.showPopAnimation = false;
//            //递归调用一次
//            [wself collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
        }];
    }
    
   // if (wself.isShowing == false) { return;} //优先加载第一张
    //如果传进来的本身是图片,则直接返回,无须提前下载
    if ([self.dataArr.firstObject isKindOfClass:[UIImage class]]) return;
    //预加载
    //[self preloadImageWithModel:model];
}



#pragma mark - 预加载图片
/**只提前加载前后两张图片*/
-(void)preloadImageWithModel:(AKScrollViewStatusModel *)model{
    // weak_self;
    
    //不需要预加载直接return
    if (![PhotoBrowserManager defaultManager].needPreloading) return;
   
    //left的图片
    int leftIndex = model.index -1>=0 ?  model.index -1 : 0;
    AKScrollViewStatusModel * leftModel = self.models[leftIndex];
     NSLog(@"start_leftIndex:%d",leftIndex);
    if (leftIndex!= model.index && ![AKPhotoTool getCacheImageForUrl:leftModel.url] && !self.preloadingOperationDic[@(leftIndex)]) {
        NSLog(@"stop1_leftIndex:%d",leftIndex);
        NSOperation * left_Operation = [[SDWebImageManager sharedManager]loadImageWithURL:leftModel.url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            NSLog(@"stop2_leftIndex:%d",leftIndex);
            leftModel.currentPageImage = error? [PhotoBrowserManager  defaultManager].errorImage :image;
            [self.preloadingOperationDic removeObjectForKey:@(leftIndex)];
        }];
        self.preloadingOperationDic[@(leftIndex)] = left_Operation;
    }
    
    //right的图片
    int rightIndex = model.index + 1 < self.models.count ? model.index+1 :  (int)(self.models.count - 1) ;
    NSLog(@"start_rightIndex:%d",rightIndex);
    AKScrollViewStatusModel * rightModel = self.models[rightIndex];
   
    if (rightIndex!= model.index && ![AKPhotoTool getCacheImageForUrl:rightModel.url] && !self.preloadingOperationDic[@(rightIndex)]) {
        NSLog(@"stop1_rightIndex:%d",rightIndex);
        NSOperation * right_Operation = [[SDWebImageManager sharedManager]loadImageWithURL:rightModel.url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            NSLog(@"stop2_rightIndex:%d",rightIndex);
            rightModel.currentPageImage = error? [PhotoBrowserManager  defaultManager].errorImage :image;
            [self.preloadingOperationDic removeObjectForKey:@(rightIndex)]; //这个rightIndex是临时变量,如果是一个强引用不释放的对象,则会问题
        }];
        self.preloadingOperationDic[@(rightIndex)] = right_Operation;
    }
}

#pragma mark - 更改page
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat pageWidth = self.collectionView.width;
    int page = floor((self.collectionView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    [self refreshStatusWithPage:page];
    self.pageControl.currentPage = page;
    [PhotoBrowserManager defaultManager].currentPage = page;
}

#pragma mark - 更新当前的显示页面
- (void)refreshStatusWithPage:(int)page {
    if (page == self.pageControl.currentPage ) {
        return;
    }
    for (AKScrollViewStatusModel *model in self.models) {
        model.isShowing = NO;
    }
    if (page >= 0 && page < self.models.count) {
        AKScrollViewStatusModel *model = self.models[page];
        model.isShowing = YES; //更改真正显示的状态isshowing
    }
}



#pragma mark - dealloc
- (void)dealloc {
    NSLog(@"%@ is dealloc",self.class);
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}


@end
