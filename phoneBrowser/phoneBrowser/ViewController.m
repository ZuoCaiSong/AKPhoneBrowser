//
//  ViewController.m
//  phoneBrowser
//
//  Created by 阿K on 2018/4/22.
//  Copyright © 2018年 阿K. All rights reserved.
//

#import "ViewController.h"

#import "PhotoBrowserManager.h"

#import "LBStyle1VC.h"

#import "AKTapDetectingImageView.h"
#import <SDWebImage/FLAnimatedImageView+WebCache.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /*
    AKTapDetectingImageView *imageView  = [[AKTapDetectingImageView alloc]init];
    [self.view addSubview:imageView];
    
    imageView.frame = CGRectMake(0, 150, 300, 300);
    
    [imageView sd_setImageWithURL:[NSURL URLWithString:@"http://wx1.sinaimg.cn/large/bfc243a3gy1febm7orgqfj20i80ht15x.jpg"] placeholderImage:nil options:0 completed:nil];
     */
}

- (IBAction)gogogo:(id)sender {
    
    LBStyle1VC *svc1 = [[LBStyle1VC alloc]init];
    [self.navigationController pushViewController:svc1 animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
