//
//  LRTitlebarAccessoryViewController.m
//  Locatr
//
//  Created by Dmitry Rodionov on 8/12/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "LRTitlebarAccessoryViewController.h"

@implementation LRTitlebarAccessoryViewController

- (void)loadView
{
    if (!self.lr_view) {
        [super loadView];
    } else {
        self.view = self.lr_view;
    }
}

@end
