//
//  LRInjector.m
//  Locatr
//
//  Created by Dmitry Rodionov on 8/4/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "LRInjector.h"
#import "LRLocationDog.h"
#import "LRApplicationModel.h"
#import "CLLocation+Description.h"
#import "LRLocationNotifications.h"
#import <RDInjectionWizard/RDInjectionWizard.h>

static NSString * const LRInjectionLocatrCoordinatesDidChangeNotification =
    @"LRInjectionLocatrCoordinatesDidChangeNotification";

static NSString * const LRInjectionLocatrEnableNotification =
    @"LRInjectionLocatrEnableNotification";

static NSString * const LRInjectionLocatrDisableNotification =
    @"LRInjectionLocatrDisableNotification";

@interface LRInjector()
@property NSMutableArray *injectees; /// Array of bundle IDs
@property NSMutableArray *pendingInjectees; /// Array of bundle IDs

- (void)postCoordinatesDidChangeGlobalNotification;
- (void)postDisableNotificationForTarget: (NSString *)bundleID;
@end

@implementation LRInjector

+ (instancetype)sharedInjector
{
    static LRInjector *injector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        injector = [[self class] new];
        injector.injectees = [NSMutableArray new];
        injector.pendingInjectees = [NSMutableArray new];

        // Observe applications launch & termination
        NSNotificationCenter *workspaceCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
        [workspaceCenter addObserver: injector
                            selector: @selector(applicationDidLaunched:)
                                name: NSWorkspaceDidLaunchApplicationNotification
                              object: nil];
        [workspaceCenter addObserver: injector
                            selector: @selector(applicationDidTerminated:)
                                name: NSWorkspaceDidTerminateApplicationNotification
                              object: nil];
        NSNotificationCenter *localCenter = [NSNotificationCenter defaultCenter];
        [localCenter addObserver: injector
                        selector: @selector(locationDidChange:)
                            name: LRLocationDidChangeNotification
                          object: nil];
    });

    return injector;
}

- (void)dealloc
{
    NSNotificationCenter *workspaceCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [workspaceCenter removeObserver: self];
    NSNotificationCenter *localCenter = [NSNotificationCenter defaultCenter];
    [localCenter removeObserver: self];
}

#pragma mark - Public

- (void)enableInjectionForApplication: (inout LRApplicationModel *)application
                           completion: (LRInjectorCompletionBlock)completion
{

    if (!application) {
        assert(application);
        if (completion) completion([NSError new]);
        return;
    }

    [self injectApplicationWithBundleIdentifer: application.bundleIdentifier
                                    completion:
     ^(NSError *error) {
         if (error) {
             assert(0);
             if (completion) completion(error);
         } else {
             [application setState: LRApplicationModelStateEnabled];
             [self postCoordinatesDidChangeGlobalNotification];
             if (completion) completion(nil);
         }
     }];
}

/** Well we don't unload the pyload library there, but just post a "Disable» notification */
- (void)disableInjectionForApplication: (inout LRApplicationModel *)application
{
    if (!application) {
        assert(application);
        return;
    }
    if (![self.pendingInjectees containsObject: application.bundleIdentifier]) {
        [self postDisableNotificationForTarget: application.bundleIdentifier];
    }
    application.state = LRApplicationModelStateDisabled;
    [self.injectees removeObject: application.bundleIdentifier];
    [self.pendingInjectees removeObject: application.bundleIdentifier];
}

#pragma mark - NSWorkspace Notifications

- (void)applicationDidLaunched: (NSNotification *)notification
{
    NSRunningApplication *application = notification.userInfo[NSWorkspaceApplicationKey];
    if (!application) return;
    /* Re-inject application */
    if ([self.pendingInjectees containsObject: application.bundleIdentifier]) {
        [self injectApplicationWithBundleIdentifer: application.bundleIdentifier
                                        completion:
         ^(NSError *error) {
             [self postCoordinatesDidChangeGlobalNotification];
         }];
        [self.pendingInjectees removeObject: application.bundleIdentifier];
    }
}

- (void)applicationDidTerminated: (NSNotification *)notification
{
    NSRunningApplication *application = notification.userInfo[NSWorkspaceApplicationKey];
    if (!application) return;
    /* Move application to the pending group */
    if ([self.injectees containsObject: application.bundleIdentifier]) {
        [self.pendingInjectees addObject: application.bundleIdentifier];
        [self.injectees removeObject: application.bundleIdentifier];
    }
}

#pragma mark - Local Notifications

- (void)locationDidChange: (NSNotification *)notification
{
    [self postCoordinatesDidChangeGlobalNotification];
}


#pragma mark - Private implementation

- (void)injectApplicationWithBundleIdentifer: (NSString *)bundleID
                                  completion: (LRInjectorCompletionBlock)completion
{
    if ([self.injectees containsObject: bundleID]) {
        [self postEnableNotificationForTarget: bundleID];
        if (completion) completion(nil);
        return;
    }
    NSArray *applications = [NSRunningApplication runningApplicationsWithBundleIdentifier: bundleID];
    if (applications.count == 0) {
        [self.pendingInjectees addObject: bundleID];
        if (completion) completion(nil);
        return;
    }

    NSString *payloadLocation = [[NSBundle mainBundle] pathForResource: @"libunicorn"
                                                                ofType: @"dylib"];
    if (payloadLocation.length == 0) {
        assert(payloadLocation.length > 0);
        if (completion) completion([NSError new]);
        return;
    }
    __block NSUInteger count = 0;
    NSUInteger total = applications.count;

    [applications enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        NSRunningApplication *app = obj;
        [self.injectees addObject: app.bundleIdentifier];
        RDInjectionWizard *wizard = [[RDInjectionWizard alloc] initWithTarget: app.processIdentifier
                                                                      payload: payloadLocation];
        [wizard injectUsingCompletionBlockWithSuccess: ^{
            ++count;
            if (count == total) {
                if (completion) completion(nil);
                *stop = YES;
            }
        } failure: ^(RDInjectionError errorCode) {
            if (count == total) {
                NSError *error = [NSError errorWithDomain: @"me.rodionovd.RDInjectionWizardDomain"
                                                     code: errorCode
                                                 userInfo: nil];
                if (completion) completion(error);
                *stop = YES;
            }
        }];
    }];
}

#pragma mark - Global Notifications

- (void)postCoordinatesDidChangeGlobalNotification
{
    CLLocation *currentLocation = [[LRLocationDog sharedDog] currentLocation];
    if (!currentLocation) return;

    NSDictionary *locationPrefs = @{
        @"location": [currentLocation lr_coordinatesString]
    };
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    [center postNotificationName: LRInjectionLocatrCoordinatesDidChangeNotification
                          object: nil
                        userInfo: locationPrefs
              deliverImmediately: YES];
}

- (void)postEnableNotificationForTarget: (NSString *)bundleID
{
    NSDictionary *targetPrefs = @{@"target" : bundleID};
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    [center postNotificationName: LRInjectionLocatrEnableNotification
                          object: nil
                        userInfo: targetPrefs
              deliverImmediately: YES];
}

- (void)postDisableNotificationForTarget: (NSString *)bundleID
{
    NSDictionary *targetPrefs = @{@"target" : bundleID};
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    [center postNotificationName: LRInjectionLocatrDisableNotification
                          object: nil
                        userInfo: targetPrefs
              deliverImmediately: YES];
}

@end
