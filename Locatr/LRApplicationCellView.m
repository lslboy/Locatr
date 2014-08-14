//
//  LTApplicationCellView.m
//  Locatr
//
//  Created by Dmitry Rodionov on 7/29/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "LRApplicationCellView.h"
#import "LRApplicationModel.h"

@implementation LRApplicationCellView

- (void)updateSwitchButton
{
    NSLog(@"Updating UI for (%@) with state: %ld", self.model.title, self.model.state);
    [self.checkbox setBordered: NO];
    [self.checkbox setEnabled: YES];
    switch (self.model.state) {
        case LRApplicationModelStateDisabled:
            break;
        case LRApplicationModelStateEnabled:
            break;
        case LRApplicationModelStateError:
            break;
        case LRApplicationModelStateFuckedUp:
            break;
        default:
            break;
    }
}

@end
