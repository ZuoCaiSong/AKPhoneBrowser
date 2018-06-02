//
//  PhotoBrowserManager.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoBrowserManager : NSObject

/**展示图片使用collectionView*/

@property(nonatomic,weak)UICollectionView  *currentCollectionView;

/**传入imageView的frames*/
@property(nonatomic,strong)NSMutableArray <NSValue *> * frames;

/** 当前选中的页 */
@property (nonatomic , assign)NSInteger currentPage;

/**每张正在加载图片的占位图*/
@property(nonatomic,copy,readonly) UIImage *(^ placeholdImageCallBackBlock)(NSIndexPath * indexPath) ;

/**每张正在加载图片的占位图的大小*/
@property(nonatomic,copy,readonly) CGSize (^ placeholdImageSizeBlock)(UIImage * Image,NSIndexPath * indexPath) ;

/**传入的imageView的共同父View*/
@property(nonatomic,weak,readonly)UIView  *imageViewSuperView;

/**关于联动的信息*/
@property(nonatomic,strong)NSMutableDictionary  *linkageInfo;

/**当图片加载出现错误时候显示的图片  default is [UIImage imageNamed:@"LBLoadError.png"]*/
@property(nonatomic,strong)UIImage  *errorImage; //如果LBLoadError.png这张图片不满意 可以修改这个属性替换

/**
 是否需要预加载 default is YES
 每次LBPhotoBrowser -> did dismiss(消失)的时候,LBPhotoBrowserManager 会将 needPreloading 置为YES,
 故:如果需要修改该选项 需要每次弹出LBPhotoBrowser的时候 将needPreloading 置为 NO;
 */
@property(nonatomic,assign)BOOL needPreloading;

/**
 返回一个单利
 @return 单利
 */
+ (instancetype)defaultManager;

@end
