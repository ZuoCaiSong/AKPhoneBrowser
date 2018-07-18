//
//  LBCell.m
//  test
//
//  Created by dengweihao on 2017/12/26.
//  Copyright © 2017年 dengweihao. All rights reserved.
//

#import "LBCell.h"

#import <SDWebImage/FLAnimatedImageView+WebCache.h>
#import "NSData+ImageContentType.h"


@interface LBCell()
/**dongtu*/
@property(nonatomic,strong) NSMutableDictionary *dic ;
@end

@implementation LBCell

-(NSMutableDictionary *)dic{
    if (!_dic) {
        _dic = [NSMutableDictionary dictionary];
    }
    return _dic;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setUpUI];
    }
    return self;
}
- (NSMutableArray *)imageViews {
    if (!_imageViews) {
        _imageViews = [[NSMutableArray alloc]init];
    }
    return _imageViews;
}

- (void)setUpUI {
    for (int i = 0; i < 9; i++) {
        FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc]init];
        imageView.userInteractionEnabled = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.backgroundColor = [UIColor lightGrayColor];
        imageView.clipsToBounds = YES;
        imageView.tag = i;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewClick:)];
        [imageView addSubview:[self addAnimatLab]];
        [imageView addGestureRecognizer:tap];
        [self.imageViews addObject:imageView];
        [self.contentView addSubview:imageView];
    }
}

- (UILabel *)addAnimatLab{
    UILabel *lab = [[UILabel alloc]init];
    lab.text = @"动图";
    lab.backgroundColor = UIColor.redColor;
    [lab sizeToFit];
    lab.hidden = true;
    lab.tag = 22;
   // CGPoint origin = CGPointZero;
    
    return lab;
}

- (void)setModel:(LBModel *)model {
    _model = model;
    LB_WEAK_SELF;
    [self.imageViews enumerateObjectsUsingBlock:^(FLAnimatedImageView*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        obj.hidden = YES;
        obj.image = nil;
        obj.animatedImage = nil;
    }];
    [model.frames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        FLAnimatedImageView *imageV = wself.imageViews[idx];
        imageV.hidden = NO;
        imageV.frame = [model.frames[idx] CGRectValue];
       
        [imageV sd_setImageWithURL:[NSURL URLWithString:model.urls[idx].thumbnailURLString] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            
            if (image.images.count >0) { //gif
                self.dic[@(imageV.tag)] = imageV;
                [imageV viewWithTag:22].hidden = false;
                [imageV stopAnimating];
                
            } else {
                 [imageV viewWithTag:22].hidden = true;
                
            }
        }];
    }];
}

-(void)allok:(NSInteger)i{
    NSArray * keys = self.dic.allKeys;
    NSNumber * key = keys[i];
    FLAnimatedImageView * imageV = self.dic[key];
    
    __weak typeof(FLAnimatedImageView *)weakImagev = imageV;
    [imageV startAnimating];
    imageV.loopCompletionBlock = ^(NSUInteger loopCountRemaining) {
        [weakImagev stopAnimating ];
        NSInteger index = i+1==keys.count? 0: i+1;
        [self allok: index];
    };
    
}



- (void)imageViewClick:(UITapGestureRecognizer *)tap {
//    if (_callBack) {
//        _callBack(self.model,tap.view.tag);
//    }
    [self allok:0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{return;}
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{return;}
@end
