//
//  AKPhotoCollectionViewCell.h
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AKZoomScrollView.h"

@interface AKPhotoCollectionViewCell : UICollectionViewCell

/**scrollview,用于放大缩小图片*/
@property(nonatomic,strong) AKZoomScrollView  * zoomScrollView ;

@end
