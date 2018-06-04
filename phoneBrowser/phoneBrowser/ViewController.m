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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
