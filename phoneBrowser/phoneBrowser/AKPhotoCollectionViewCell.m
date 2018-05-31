//
//  AKPhotoCollectionViewCell.m
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "AKPhotoCollectionViewCell.h"

@implementation AKPhotoCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        //1.添加UI
        [self createUI];
        //2.添加手势
        [self addGesture];
    }
    return self;
}

#pragma mark - 添加收拾
-(void)addGesture{
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    //单击
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self addGestureRecognizer:tap];
    [self addGestureRecognizer:doubleTap];
    //防止手势冲突
    [tap requireGestureRecognizerToFail:doubleTap];
}

#pragma mark - 创建UI
-(void)createUI{
    _zoomScrollView = [[AKZoomScrollView alloc]init];
    [self.contentView addSubview:_zoomScrollView];
}

-(void)setModel:(AKScrollViewStatusModel *)model{
    _model = model;
    _zoomScrollView.model = model;
}

- (void)didTap:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:tap.view];
    [_zoomScrollView handleSingleTap:point];
}

- (void)didDoubleTap:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:tap.view];
    if (!CGRectContainsPoint(_zoomScrollView.imageView.bounds, point)) {
        return;
    }
    [_zoomScrollView handleDoubleTap:point];
}

- (void)startPopAnimationWithModel:(AKScrollViewStatusModel *)model completionBlock:(void(^)(void))completion {
    [_zoomScrollView startPopAnimationWithModel:model completionBlock:completion];
}

@end
