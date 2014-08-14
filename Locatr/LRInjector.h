//
//  LRInjector.h
//  Locatr
//
//  Created by Dmitry Rodionov on 8/4/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LRApplicationModel;

typedef void (^LRInjectorCompletionBlock)(NSError *error);

@interface LRInjector : NSObject

+ (instancetype)sharedInjector __attribute__((const));

- (void)enableInjectionForApplication: (inout LRApplicationModel *)application
                           completion: (LRInjectorCompletionBlock)completion;

- (void)disableInjectionForApplication: (inout LRApplicationModel *)application;
@end
