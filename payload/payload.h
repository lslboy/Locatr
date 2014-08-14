//
//  payload.h
//  payload
//
//  Created by Dmitry Rodionov on 8/5/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LRPayload : NSObject
@property (readonly) BOOL shouldFakeLocation;
@property (readonly) CLLocationCoordinate2D fakeCoordinate2D;

+ (instancetype)sharedPayload;

@end
