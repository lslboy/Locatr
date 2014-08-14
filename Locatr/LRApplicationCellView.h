//
//  LTApplicationCellView.h
//  Locatr
//
//  Created by Dmitry Rodionov on 7/29/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class LRApplicationModel;

@interface LRApplicationCellView : NSTableCellView

@property (strong) LRApplicationModel *model;
@property (weak) IBOutlet NSButton *checkbox;

- (void)updateSwitchButton;
@end
