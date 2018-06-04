//
//  AKPhotoWebItem.h
//  phoneBrowser
//
//  Created by LEO on 2018/6/4.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AKPhotoWebItem : NSObject

// 加载图片的url
@property (nonatomic , copy)NSString *urlString;

//imageView的frame
@property (nonatomic , assign)CGRect frame;

//站位图的大小
@property (nonatomic , assign)CGSize placeholdSize;

//占位图片  default is [UIImage imageNamed:@"LBLoading.png"]
@property (nonatomic , strong)UIImage *placeholdImage;


/**
 创建实例

 @param url 图片对应的url
 @param frame iamgeView对应的frame值
 @return 实例
 */
- (instancetype)initWithURLString:(NSString *)url frame:(CGRect)frame;


/**
 创建实例
 
 @param url 图片对应的url
 @param frame iamgeView对应的frame值
 @param image 占位图
 @return 实例
 */
- (instancetype)initWithURLString:(NSString *)url frame:(CGRect)frame placeholdImage:(UIImage *)image;


/**
 创建实例
 
 @param url 图片对应的url
 @param frame iamgeView对应的frame值
 @param size 占位图的size
 @return 实例
 */
- (instancetype)initWithURLString:(NSString *)url frame:(CGRect)frame placeholdSize:(CGSize)size;


/**
 创建实例
 
 @param url 图片对应的url
 @param frame iamgeView对应的frame值
 @param image 占位图
 @param size 占位图的size
 @return 实例
 */
- (instancetype)initWithURLString:(NSString *)url frame:(CGRect)frame placeholdImage:(UIImage *)image placeholdSize:(CGSize)size;


@end
