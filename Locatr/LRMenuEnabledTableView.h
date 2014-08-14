//
//  LRMenuEnabledTableView.h
//  Locatr
//
//  Created by Dmitry Rodionov on 01.08.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LRMenuEnabledTableViewDelegate.h"

@interface LRMenuEnabledTableView : NSTableView
@property (weak) id <LRMenuEnabledTableViewDelegate> menuDelegate;
@end
