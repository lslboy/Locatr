//
//  LTApplicationModel.h
//  Locatr
//
//  Created by Dmitry Rodionov on 7/29/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, LRApplicationModelState) {
    LRApplicationModelStateDisabled,
    LRApplicationModelStateEnabled,
    LRApplicationModelStateError,
    LRApplicationModelStateFuckedUp
};

@interface LRApplicationModel : NSObject <NSSecureCoding>

@property (strong) NSURL *URL;
@property (strong) NSImage *icon;
@property (copy) NSString *title;
@property (copy) NSString *bundleIdentifier;
@property (assign) LRApplicationModelState state;

+ (instancetype)modelForApplicationAtURL: (NSURL *)url;

@end
