//
//  LRTitlebarAccessoryViewController.h
//  Locatr
//
//  Created by Dmitry Rodionov on 8/12/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * LRTitlebarAccessoryViewController header file notes that we shouldn't override the -view
 * property directly, so let's use custom subclass and override -loadView method instead.
 */
@interface LRTitlebarAccessoryViewController : NSTitlebarAccessoryViewController

@property (strong) NSView *lr_view; // Will be used as -view
@end
