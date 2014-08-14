//
//  CLLocationManager+FakeLocation.m
//  Locatr
//
//  Created by Dmitry Rodionov on 8/10/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "CLLocationManager+FakeLocation.h"
#import "payload.h"
#import <objc/runtime.h>

@implementation CLLocationManager (FakeLocation)

+ (void)load
{
    @autoreleasepool {
        [LRPayload sharedPayload];
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class targetClass = [self class];
            Method originalMethod = class_getInstanceMethod(targetClass, sel_registerName("onClientEventLocation:"));
            Method newMethod = class_getInstanceMethod(targetClass, @selector(lr_onClientEventLocation:));

            if (! (originalMethod && newMethod)) {
                return;
            }
            method_exchangeImplementations(originalMethod, newMethod);
        });
    }
}

- (void)lr_onClientEventLocation: (NSDictionary *)info
{
    Ivar internalIvar = class_getInstanceVariable(self.class, "_internal");
    id <NSObject> internal = object_getIvar(self, internalIvar);
    Ivar fDelegateivar = class_getInstanceVariable(internal.class, "fDelegate");
    id <CLLocationManagerDelegate> delegate = object_getIvar(internal, fDelegateivar);

    /* We'll proxy the delegate's methods in order to replace original location value with
     * a fake one */
    SEL proxyDidUpdateLocations = sel_registerName("lr_proxy_locationManager:didUpdateLocations:");
    SEL proxyDidUpdateToLocationFromLocation = sel_registerName("lr_proxy_locationManager:didUpdateToLocation:fromLocation:");

    BOOL alreadyFixed = [delegate respondsToSelector: proxyDidUpdateLocations] ||
        [delegate respondsToSelector: proxyDidUpdateToLocationFromLocation];

    if (!delegate || alreadyFixed) {
        [self lr_onClientEventLocation: info];
        return;
    }

    Class targetClass = delegate.class;
    Method originalMethod = NULL;
    SEL validProxy = NULL;

    /* Since Core Location has a new API, we have to support both.
     * But only one callback at the time, so decide which one. */
    SEL newAPISelector = @selector(locationManager:didUpdateLocations:);
    SEL oldAPISelector = @selector(locationManager:didUpdateToLocation:fromLocation:);
    if ([delegate respondsToSelector: newAPISelector]) {
        validProxy = proxyDidUpdateLocations;
        originalMethod = class_getInstanceMethod(targetClass, newAPISelector);
    } else if ([delegate respondsToSelector: oldAPISelector]) {
        /* Fallback to old API */
        validProxy = proxyDidUpdateToLocationFromLocation;
        originalMethod = class_getInstanceMethod(targetClass, oldAPISelector);
    } else {
        /* This delegate doesn't even deal with locations */
        [self lr_onClientEventLocation: info];
        return;
    }

    if (!(originalMethod && validProxy)) {
        [self lr_onClientEventLocation: info];
        return;
    }

    Method proxyMethod = class_getInstanceMethod(self.class, validProxy);
    BOOL added = class_addMethod(targetClass, validProxy,
                                 method_getImplementation(proxyMethod),
                                 method_getTypeEncoding(proxyMethod));
    if (!added) {
        [self lr_onClientEventLocation: info];
        return;
    }

    Method newMethod = class_getInstanceMethod(targetClass, validProxy);
    method_exchangeImplementations(originalMethod, newMethod);

    [self lr_onClientEventLocation: info];
}

- (void)lr_proxy_locationManager:(CLLocationManager *)manager didUpdateLocations: (id)locations
{
    if ([[LRPayload sharedPayload] shouldFakeLocation] == NO) {
        [self lr_proxy_locationManager: manager didUpdateLocations: locations];
        return;
    }

    CLLocation *mostRecentLocation = nil;
    /* Sometimes CLLocationManager provides us with a single instance of CLLocation instead of
     * an array with one item. */
    BOOL locationIsArray = NO;
    if ([locations isKindOfClass: NSArray.class]) {
        locationIsArray = YES;
        mostRecentLocation = [(NSArray *)locations lastObject];
    } else if ([locations isKindOfClass: CLLocation.class]) {
        mostRecentLocation = locations;
    } else {
        [self lr_proxy_locationManager: manager didUpdateLocations: locations];
        return;
    }

    CLLocation *fakeLocation = [CLLocationManager fakeLocationInheritedFrom: mostRecentLocation];
    if (!locationIsArray) {
        [self lr_proxy_locationManager: manager didUpdateLocations: fakeLocation];
    } else {
        NSMutableArray *fixedLocations = [NSMutableArray arrayWithArray: locations];
        [fixedLocations replaceObjectAtIndex: (fixedLocations.count-1) withObject: fakeLocation];
        [self lr_proxy_locationManager: manager didUpdateLocations: fixedLocations];
    }
}

- (void)lr_proxy_locationManager: (CLLocationManager *)manager
             didUpdateToLocation: (CLLocation *)newLocation
                    fromLocation: (CLLocation *)oldLocation
{
    if ([[LRPayload sharedPayload] shouldFakeLocation] == NO) {
        [self lr_proxy_locationManager: manager didUpdateToLocation: newLocation fromLocation: oldLocation];
        return;
    }

    [self lr_proxy_locationManager: manager
               didUpdateToLocation: [CLLocationManager fakeLocationInheritedFrom: newLocation]
                      fromLocation: oldLocation];
}

#pragma mark - Misc

+ (CLLocation *)fakeLocationInheritedFrom: (CLLocation *)originalLocation
{
    LRPayload *payload = [LRPayload sharedPayload];
    CLLocation *fakeLocation = [[CLLocation alloc] initWithCoordinate: payload.fakeCoordinate2D
                                                             altitude: originalLocation.altitude
                                                   horizontalAccuracy: originalLocation.horizontalAccuracy
                                                     verticalAccuracy: originalLocation.verticalAccuracy
                                                               course: originalLocation.course
                                                                speed: originalLocation.speed
                                                            timestamp: [NSDate new]];
    return fakeLocation;
}

@end
