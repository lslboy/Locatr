//
//  payload.m
//  payload
//
//  Created by Dmitry Rodionov on 8/5/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//
@import CoreLocation;
#include <objc/runtime.h>
#import "payload.h"

static NSString * const LRInjectionLocatrCoordinatesDidChangeNotification =
    @"LRInjectionLocatrCoordinatesDidChangeNotification";

static NSString * const LRInjectionLocatrEnableNotification =
    @"LRInjectionLocatrEnableNotification";

static NSString * const LRInjectionLocatrDisableNotification =
    @"LRInjectionLocatrDisableNotification";

@interface LRPayload()
@property (readwrite) BOOL shouldFakeLocation;
@property (readwrite) CLLocationCoordinate2D fakeCoordinate2D;
@end

@implementation LRPayload

+ (instancetype)sharedPayload
{
    static LRPayload *payload = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        payload = [LRPayload new];
    });

    return payload;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _shouldFakeLocation = YES;
        NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
        [center addObserver: self
                   selector: @selector(locationDidChange:)
                       name: LRInjectionLocatrCoordinatesDidChangeNotification
                     object: nil];
        [center addObserver: self
                   selector: @selector(enableLocationUpdates:)
                       name: LRInjectionLocatrEnableNotification
                     object: nil];
        [center addObserver: self
                   selector: @selector(disableLocationUpdates:)
                       name: LRInjectionLocatrDisableNotification
                     object: nil];
    }
    
    return self;
}

- (void)dealloc
{
    _shouldFakeLocation = NO;
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    [center removeObserver: self];
}

#pragma mark - Notifications handling

- (void)locationDidChange: (NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSArray *coordinates = [userInfo[@"location"] componentsSeparatedByString: @", "];
    if (coordinates.count != 2) return;
    
    CLLocationCoordinate2D coordinate = {
        [coordinates[0] doubleValue], // latitude
        [coordinates[1] doubleValue]  // longitude
    };
    self.fakeCoordinate2D = coordinate;
}

- (void)enableLocationUpdates: (NSNotification *)notification
{
    self.shouldFakeLocation = YES;
}

- (void)disableLocationUpdates: (NSNotification *)notification
{
    self.shouldFakeLocation = NO;
}

@end
