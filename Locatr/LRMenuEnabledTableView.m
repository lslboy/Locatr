//
//  LRMenuEnabledTableView.m
//  Locatr
//
//  Created by Dmitry Rodionov on 01.08.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "LRMenuEnabledTableView.h"

@implementation LRMenuEnabledTableView

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    NSMenu *menu = nil;
    NSPoint mousePoint = [self convertPoint: [event locationInWindow] fromView: nil];
    NSInteger coveredRow = [self rowAtPoint: mousePoint];
    NSInteger coveredColumn = [self columnAtPoint: mousePoint];

    if (event.type == NSLeftMouseDown) {
        if ([self.menuDelegate respondsToSelector: @selector(leftMouseMenuForTableView:column:row:)]) {
            menu = [self.menuDelegate leftMouseMenuForTableView: self
                                                         column: coveredColumn
                                                            row: coveredRow];
        }
    } else if (event.type == NSRightMouseDown) {
        if ([self.menuDelegate respondsToSelector: @selector(rightMouseMenuForTableView:column:row:)]) {
            menu = [self.menuDelegate rightMouseMenuForTableView: self
                                                          column: coveredColumn
                                                             row: coveredRow];
        }
    }

    if (!menu) {
        menu = [super menuForEvent: event];
    }

    return menu;
}

@end
