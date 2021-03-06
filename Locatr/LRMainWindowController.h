//
//  LRMainWindowController.h
//  Locatr
//
//  Created by Dmitry Rodionov on 31.07.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LRAppsListManager;

@interface LRMainWindowController : NSWindowController

@property (weak) IBOutlet NSButton *buttomLocationButton;
@property (strong) IBOutlet LRAppsListManager *appsListManager;

- (void)showWindowWithActivatedPopover: (id)sender;
- (IBAction)addApplicationToList: (id)sender;

@end
