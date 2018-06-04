//
//  AKPhotoWebItem.m
//  phoneBrowser
//
//  Created by LEO on 2018/6/4.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "AKPhotoWebItem.h"

@implementation AKPhotoWebItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        _frame = CGRectZero;
        _placeholdSize = CGSizeZero;
        _urlString = @"";
    }
    return self;
}

- (instancetype)initWithURLString:(NSString *)url frame:(CGRect)frame {
    AKPhotoWebItem *item  = [self init];
    item.urlString = url;
    item.frame = frame;
    return item;
}

- (instancetype)initWithURLString:(NSString *)url frame:(CGRect)frame placeholdSize:(CGSize)size {
    AKPhotoWebItem *item = [self initWithURLString:url frame:frame];
    item.placeholdSize = size;
    return item;
}

- (instancetype)initWithURLString:(NSString *)url frame:(CGRect)frame placeholdImage:(UIImage *)image {
    AKPhotoWebItem *item = [self initWithURLString:url frame:frame];
    item.placeholdImage = image;
    return item;
}

- (instancetype)initWithURLString:(NSString *)url frame:(CGRect)frame placeholdImage:(UIImage *)image placeholdSize:(CGSize)size  {
    AKPhotoWebItem *item = [self initWithURLString:url frame:frame placeholdImage:image];
    item.placeholdSize = size;
    return item;
}

@end
