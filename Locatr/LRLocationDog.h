//
//  LRLocationDog.h
//  Locatr
//
//  Created by Dmitry Rodionov on 02.08.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//
#import <Foundation/Foundation.h>
@class CLLocation;

typedef void (^LRLocationDogSuccessCallback)(void);
typedef void (^LRLocationDogFailureCallback)(NSError *error);

@interface LRLocationDog : NSObject
@property (readonly, strong) CLLocation *currentLocation;
@property (copy) void (^locationServicesAuthStatusDidChangeCallback)(BOOL enabled);

+ (instancetype)sharedDog __attribute__((const));

- (BOOL)canRollbackToPreviousLocation;
- (void)rollbackToPreviousLocationWithSuccess: (LRLocationDogSuccessCallback)success
                                      failure: (LRLocationDogFailureCallback)failure;

- (void)restoreOriginalLocationWithSuccess: (LRLocationDogSuccessCallback)success
                                   failure: (LRLocationDogFailureCallback)failure;

- (NSString *)currentLocationPrettyDescription;
- (NSString *)currentLocationFullDescription;
- (NSString *)currentLocationCoordinatesString;

- (void)updateLocationWithQueue: (NSString *)queue
                        success: (LRLocationDogSuccessCallback)complition
                        failrue: (LRLocationDogFailureCallback)failure;
@end
