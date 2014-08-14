//
//  LRAppDelegate.h
//  Locatr
//
//  Created by Dmitry Rodionov on 31.07.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class LRMainWindowController;

@interface LRAppDelegate : NSObject <NSApplicationDelegate>
@property (strong) IBOutlet LRMainWindowController *mainWindowController;
@end
