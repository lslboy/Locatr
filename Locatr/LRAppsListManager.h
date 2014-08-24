//
//  LTAppsListControlller.h
//  Locatr
//
//  Created by Dmitry Rodionov on 7/29/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "LRMenuEnabledTableViewDelegate.h"

@class LRApplicationModel;
@class LRMenuEnabledTableView;

@interface LRAppsListManager : NSObject
<NSTableViewDataSource, NSTableViewDelegate, LRMenuEnabledTableViewDelegate>

@property (strong) IBOutlet LRMenuEnabledTableView *tableView;

- (void)disableAllLocationChanges;
- (void)addApplicationsWithURL: (NSArray *)urls;
- (IBAction)toggleSwitch: (id)sender;

@end
