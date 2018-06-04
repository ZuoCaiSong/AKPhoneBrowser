//
//  PhotoBrowserManager.m
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "PhotoBrowserManager.h"
#import "Config.h"
#import "PhotoBrowserView.h"

#import "AKPhotoWebItem.h"
#import "AKPhotoLocalItem.h"

//static inline PhotoBrowserManager * getPhotoBrowserManager(){
//    return PhotoBrowserManager.defaultManager ;
//}

//作为一个单利需要在每次重置一些数据
static inline void resetManagerData(PhotoBrowserView *photoBrowseView, NSMutableArray<NSURL *> *urls ,NSMutableArray<NSValue *> *frames, NSMutableArray<UIImage *> *images) {
    [urls removeAllObjects];
    [frames removeAllObjects];
    [images removeAllObjects];
    if (photoBrowseView) {
        [photoBrowseView removeFromSuperview];
    }
}

@interface PhotoBrowserManager ()

/**
 长按时,选中的某一项的回调
 */
@property (nonatomic , copy)void (^titleClickBlock)(UIImage *, NSIndexPath *, NSString *);

/**
 长按的回调
 */
@property (nonatomic , copy)UIView *(^longPressCustomViewBlock)(UIImage *, NSIndexPath *);

/**
 图片浏览器willdismiss的回调
 */
@property (nonatomic , copy)void(^willDismissBlock)(void);

/**
 图片浏览器diddismiss的回调
 */
@property (nonatomic , copy)void(^didDismissBlock)(void);

/**
 长按时的title
 */
@property (nonatomic , strong)NSArray *titles;

@end

static PhotoBrowserManager * mgr = nil;

@implementation PhotoBrowserManager

@synthesize urls = _urls;
@synthesize frames = _frames;
@synthesize images = _images;
@synthesize linkageInfo = _linkageInfo;

#pragma mark - 创建一个单例对象

+ (instancetype)defaultManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[self alloc]init];
    });
    return mgr;
}

#pragma mark - 懒加载区域

-(NSMutableArray<NSURL *> *)urls{
    if (!_urls) {
        _urls = [NSMutableArray array];
    }
    return _urls;
}

-(NSMutableArray<NSValue *> *)frames{
    if (!_frames) {
        _frames = [NSMutableArray array];
    }
    return _frames;
}

-(NSMutableArray<UIImage *> *)images{
    if (!_images) {
        _images = [NSMutableArray array];
    }
    return _images;
}
- (NSMutableDictionary *)linkageInfo {
    if (!_linkageInfo) {
        _linkageInfo = [NSMutableDictionary dictionary];
    }
    return _linkageInfo;
}




- (instancetype)init {
    self = [super init];
    if (self) {
        
        //2.注册通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoBrowserWillDismiss) name:AKImageViewWillDismissNoti object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoBrowserDidDismiss) name:AKImageViewDidDismissNoti object:nil];
         _errorImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"LBLoadError.png" ofType:nil]];
        _needPreloading = YES;
    }
    
    return self;
}


- (instancetype)showImageWithLocalItems:(NSArray<AKPhotoLocalItem *> *)items selectedIndex:(NSInteger)index fromImageViewSuperView:(UIView *)superView {
    if (items.count == 0 || !items) { return nil; }
    //1. 重置数据
    resetManagerData(_photoBrowserView, self.urls, self.frames, self.images);
    //重新构建本地的item
    for(int i = 0; i<items.count; i++){
        AKPhotoLocalItem * item = items[i];
        if (item.localImage) {
            [self.images addObject:item.localImage];
        }
        if (!CGRectEqualToRect(item.frame, CGRectZero)) {
            [self.frames addObject:[NSValue valueWithCGRect:item.frame]];
        }
    }
    NSAssert(self.images.count == self.frames.count, @"请检查传入item的localImage 和 frame");
    _currentPage = index;
    _imageViewSuperView = superView;
    
    _photoBrowserView = [[PhotoBrowserView alloc]initWithFrame: [UIScreen mainScreen].bounds];
    [_photoBrowserView showImageViewsWithURLsOrImages:self.images andSelectedIndex:index];
    [_photoBrowserView makeKeyAndVisible];
    
    return self;
    
}

- (instancetype)showImageWithWebItems:(NSArray<AKPhotoWebItem *> *)items selectedIndex:(NSInteger)index fromImageViewSuperView:(UIView *)superView {
    NSMutableDictionary *placeHoldImageDic = [[NSMutableDictionary alloc]initWithCapacity:items.count];
    NSMutableDictionary *placeholdSizeDic = [[NSMutableDictionary alloc]initWithCapacity:items.count];
    NSMutableArray *frames = [[NSMutableArray alloc]initWithCapacity:items.count];
    NSMutableArray *urls = [[NSMutableArray alloc]initWithCapacity:items.count];
    for (int i = 0; i < items.count; i++) {
        AKPhotoWebItem *item = items[i];
        if (!item.urlString || CGRectEqualToRect(item.frame, CGRectZero)) {
            return nil;
        }
        [urls addObject:item.urlString];
        [frames addObject:[NSValue valueWithCGRect:item.frame]];
        NSString *index = [NSString stringWithFormat:@"%d",i];
        placeHoldImageDic[index] = item.placeholdImage;
        placeholdSizeDic[index] = CGSizeEqualToSize(item.placeholdSize, CGSizeZero)? nil:[NSValue valueWithCGSize:item.placeholdSize];
    }
    /*
    return  [[[self showImageWithURLArray:urls fromImageViewFrames:frames selectedIndex:index imageViewSuperView:superView] addPlaceholdImageSizeBlock:^CGSize(UIImage *Image, NSIndexPath *indexpath) {
        NSString *index = [NSString stringWithFormat:@"%ld",(long)indexpath.row];
        CGSize size = [placeholdSizeDic[index] CGSizeValue];
        return size;
    }] addPlaceholdImageCallBackBlock:^UIImage *(NSIndexPath *indexPath) {
        NSString *index = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
        return placeHoldImageDic[index];
    }] ;
     */
    return [self showImageWithURLArray:urls fromImageViewFrames:frames selectedIndex:index imageViewSuperView:superView];
}

- (instancetype)showImageWithURLArray:(NSArray *)urls fromImageViewFrames:(NSArray *)frames selectedIndex:(NSInteger)index imageViewSuperView:(UIView *)superView {
    
    if (urls.count == 0 || !urls) return nil;
    if (frames.count == 0 || !frames) return nil;
    
    resetManagerData(_photoBrowserView, self.urls, self.frames, self.images);
    for (id obj in urls) {
        NSURL *url = nil;
        if ([obj isKindOfClass:[NSURL class]]) {
            url = obj;
        }
        if ([obj isKindOfClass:[NSString class]]) {
            url = [NSURL URLWithString:obj];
        }
        if (!url) {
            url = [NSURL URLWithString:@"https://LBPhotoBrowser.error"];
            NSLog(@"传入的链接%@有误",obj);
        }
        [self.urls addObject:url];
    }
    
    for (id obj in frames) {
        NSValue *value = nil;
        if ([obj isKindOfClass:[NSValue class]]) {
            value = obj;
        }
        if (!value) {
            value = [NSValue valueWithCGRect:CGRectZero];
            NSLog(@"传入的frame %@有误",obj);
        }
        [self.frames addObject:value];
    }
    NSAssert(self.urls.count == self.frames.count, @"请检查传入item的url 和 frame");
    
    _currentPage = index;
    _imageViewSuperView = superView;
    _photoBrowserView = [[PhotoBrowserView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [_photoBrowserView showImageViewsWithURLsOrImages:self.urls andSelectedIndex:index];
    [_photoBrowserView makeKeyAndVisible];
    
    return self;
    
}

#pragma mark - 响应通知的方法
- (void)photoBrowserWillDismiss {
//    [self displayLinkInvalidate];
    if(self.willDismissBlock) {
        self.willDismissBlock();
    }
    self.willDismissBlock = nil;
}

- (void)photoBrowserDidDismiss {
    if (self.didDismissBlock) {
        self.didDismissBlock();
    }
    self.didDismissBlock = nil;
    self.needPreloading = YES;
  //  self.lowGifMemory = NO;
    _photoBrowserView.hidden = YES;
    _photoBrowserView = nil;
    [self.linkageInfo removeAllObjects];
}


#pragma mark - longPressAction
- (instancetype)addLongPressShowTitles:(NSArray <NSString *> *)titles {
    _titles = titles;
    return self;
}

- (instancetype)addTitleClickCallbackBlock:(void (^)(UIImage *, NSIndexPath *, NSString *))titleClickCallBackBlock {
    _titleClickBlock = titleClickCallBackBlock;
    return self;
}

- (instancetype)addLongPressCustomViewBlock:(UIView *(^)(UIImage *, NSIndexPath *))longPressBlock {
    _longPressCustomViewBlock = longPressBlock;
    return self;
}

- (instancetype)addPlaceholdImageCallBackBlock:(UIImage *(^)(NSIndexPath *))placeholdImageCallBackBlock {
    _placeholdImageCallBackBlock = placeholdImageCallBackBlock;
    return self;
}

- (instancetype)addPhotoBrowserWillDismissBlock:(void (^)(void))dismissBlock {
    _willDismissBlock = dismissBlock;
    return self;
}

- (instancetype)addPhotoBrowserDidDismissBlock:(void (^)(void))dismissBlock {
    _didDismissBlock = dismissBlock;
    return self;
}

- (instancetype)addPlaceholdImageSizeBlock:(CGSize (^)(UIImage *, NSIndexPath *))placeholdImageSizeBlock {
    _placeholdImageSizeBlock = placeholdImageSizeBlock;
    return self;
}

- (instancetype)addCollectionViewLinkageStyle:(UICollectionViewScrollPosition)style cellReuseIdentifier:(NSString *)reuseIdentifier {
    self.linkageInfo[AKLinkageInfoStyleKey] = @(style);
    self.linkageInfo[AKLinKageInfoReuseIdentifierKey] = reuseIdentifier;
    return self;
}

- (NSArray<NSString *> *)currentTitles {
    return _titles;
}

- (void (^)(UIImage *, NSIndexPath *, NSString *))titleClickBlock {
    return _titleClickBlock;
}

- (UIView *(^)(UIImage *, NSIndexPath *))longPressCustomViewBlock {
    return _longPressCustomViewBlock;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
