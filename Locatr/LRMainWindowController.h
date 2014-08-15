//
//  LRMainWindowController.h
//  Locatr
//
//  Created by Dmitry Rodionov on 31.07.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LRAppsListManager;

@interface LRMainWindowController : NSWindowController <NSOpenSavePanelDelegate>

@property (weak) IBOutlet NSButton *buttomLocationButton;
@property (strong) IBOutlet LRAppsListManager *appsListManager;

- (IBAction)addApplicationToList: (id)sender;

@end
