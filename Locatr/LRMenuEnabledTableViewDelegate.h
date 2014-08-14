//
//  LRMenuEnabledTableViewDelegate.h
//  Locatr
//
//  Created by Dmitry Rodionov on 01.08.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LRMenuEnabledTableView;

@protocol LRMenuEnabledTableViewDelegate <NSObject>

@optional
- (NSMenu *)rightMouseMenuForTableView: (LRMenuEnabledTableView *)table
                                column: (NSInteger)column
                                   row: (NSInteger)row;

- (NSMenu *)leftMouseMenuForTableView: (LRMenuEnabledTableView *)table
                               column: (NSInteger)column
                                  row: (NSInteger)row;
@end
