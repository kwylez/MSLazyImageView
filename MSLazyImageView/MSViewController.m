//
//  MSViewController.m
//  MSLazyImageView
//
//  Created by Cory D. Wiles on 3/25/14.
//  Copyright (c) 2014 Cory Wiles. All rights reserved.
//

#import "MSViewController.h"
#import "MSLazyImageView.h"

@interface MSViewController ()

@property (nonatomic, strong) MSLazyImageView *imageView;

@end

@implementation MSViewController

- (void)viewDidLoad {

  [super viewDidLoad];
  
  NSString *urlString = @"http://emmamidori.files.wordpress.com/2012/06/montreal-view-pierre-dupuy-morning-darina-velkova-2012-s.jpg";
  
  self.imageView = [[MSLazyImageView alloc] initWithFrame:CGRectMake(20, 100, 200, 200)];
  
  [self.view addSubview:self.imageView];
  
  self.imageView.imageURL = urlString;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

@end
