//
//  LRLocationDog.m
//  Locatr
//
//  Created by Dmitry Rodionov on 02.08.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//
@import CoreLocation;
#import "LRLocationDog.h"
#import "CLLocation+Description.h"
#import "LRLocationNotifications.h"

#define kLocationDogCallbacksQueueLabel "Locatr.LRLocationDog.callbacks_queue"
NSString * const LRLocationDidChangeNotification = @"LRLocationDidChangeNotification";

@interface LRLocationDog() <CLLocationManagerDelegate>

@property (strong) CLGeocoder *geocoder;
@property (strong) dispatch_queue_t callbacksQueue;
// History of locations
@property (strong) NSMutableArray *locationHistory; /// Items of class CLLocation

// A brand new fake location
@property (readwrite, strong) CLLocation *currentLocation;
@property (copy) NSDictionary *currentAddressDictionary;
// Dealing with users' original location
@property (strong) CLLocationManager *originalLocationManager;
@property (readwrite) BOOL locationServicesIsAvailable;
@end

@implementation LRLocationDog

+ (instancetype)sharedDog
{
    static LRLocationDog *dog = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dog = [LRLocationDog new];
    });

    return dog;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _geocoder = [CLGeocoder new];
        _originalLocationManager = [CLLocationManager new];
        _originalLocationManager.distanceFilter = kCLDistanceFilterNone;
        _originalLocationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        [_originalLocationManager setDelegate: self];
        [_originalLocationManager startUpdatingLocation];
        _callbacksQueue = dispatch_queue_create(kLocationDogCallbacksQueueLabel,
                                                DISPATCH_QUEUE_SERIAL);
        _locationHistory = [NSMutableArray new];

        // (Try to) turn Location Services on for this application
        [CLLocationManager locationServicesEnabled];
    }

    return self;
}

- (void)locationManager: (CLLocationManager *)manager didUpdateLocations: (NSArray *)locations
{
    @synchronized (self) {
        static BOOL initialLocationIsPublished = NO;
        if (initialLocationIsPublished) {
            return;
        }
        [self restoreOriginalLocationWithSuccess: nil failure: nil];
        initialLocationIsPublished = YES;
    }
}

#pragma mark CLLocationManagerDelegate's

/*** Check if Location Services is enabled for this application */
- (void)locationManager: (CLLocationManager *)manager didChangeAuthorizationStatus: (CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorized) {
        if (self.locationServicesAuthStatusDidChangeCallback) {
            self.locationServicesAuthStatusDidChangeCallback(YES);
        }
    }
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        if (self.locationServicesAuthStatusDidChangeCallback) {
            self.locationServicesAuthStatusDidChangeCallback(NO);
        }
    }
    if (status == kCLAuthorizationStatusNotDetermined) {
        /* Trigger Location Services deamon to promt user a dialog */
        [self.originalLocationManager stopUpdatingLocation];
        [self.originalLocationManager startUpdatingLocation];
    }
}

#pragma mark Update current location

- (void)updateLocationWithQueue: (NSString *)queue
                        success: (LRLocationDogSuccessCallback)success
                        failrue: (LRLocationDogFailureCallback)failure
{
    __weak typeof(self) welf = self;
    [self.geocoder geocodeAddressString: queue completionHandler:
     ^(NSArray *placemarks, NSError *error) {
        __strong typeof(welf) strongSelf = welf;
         if (placemarks.count == 0 || error) {
             dispatch_async(strongSelf.callbacksQueue, ^{
                 if (failure) failure(error);
             });
         } else {
             /* We probably should store all the suggested placemarks and allow
              * user to select which one to apply */
             CLPlacemark *placemark = placemarks[0];
             strongSelf.currentLocation = placemark.location;
             /* Push current location into the history stack */
             [strongSelf.locationHistory insertObject: strongSelf.currentLocation
                                              atIndex: 0];
             strongSelf.currentAddressDictionary = placemark.addressDictionary;
             dispatch_async(strongSelf.callbacksQueue, ^{
                 if (success) success();
             });

             NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
             [center postNotificationName: LRLocationDidChangeNotification
                                   object: self];
         }
     }];
}

#pragma mark - Revert any location changes

- (void)restoreOriginalLocationWithSuccess: (LRLocationDogSuccessCallback)success
                                   failure: (LRLocationDogFailureCallback)failure
{
    __weak typeof(self) welf = self;
    [self updateLocationWithQueue: [self.originalLocationManager.location lr_coordinatesString]
                          success: ^{
                              __strong typeof(welf) strongSelf = welf;
                              /* We won't store an original location in the history */
                              if (strongSelf.locationHistory.count > 0) {
                                  [strongSelf.locationHistory removeObjectAtIndex: 0];
                              }
                              if (success) success();
                          } failrue: failure];
}

#pragma mark - Back in time

- (BOOL)canRollbackToPreviousLocation
{
    return (self.locationHistory.count > 0);
}

- (void)rollbackToPreviousLocationWithSuccess: (LRLocationDogSuccessCallback)success
                                      failure: (LRLocationDogFailureCallback)failure
{
    if (self.locationHistory.count == 0) {
        success();
        return;
    }
    /* Pop current history stack item out */
    [self.locationHistory removeObjectAtIndex: 0];
    /* If we ran out of items: restore an original location */
    if (self.locationHistory.count == 0) {
        [self restoreOriginalLocationWithSuccess: success failure: failure];
    } else {
        /* Otherwise use a top item from the history */
        NSString *queue = [[self.locationHistory firstObject] lr_coordinatesString];
        [self.locationHistory removeObjectAtIndex: 0];
        [self updateLocationWithQueue: queue success: success failrue: failure];
    }
}


#pragma mark - Pretty format 

- (NSString *)currentLocationPrettyDescription
{
    NSDictionary *address = self.currentAddressDictionary;
    NSMutableArray *strippedAddress = [NSMutableArray arrayWithCapacity: address.count];
    NSString *countryCode = address[@"CountryCode"];
    if (countryCode.length > 0) {
        [strippedAddress insertObject: countryCode
                              atIndex: 0];
    }
    NSString *state = address[@"State"];
    if (state && state.length <= 5) {
        [strippedAddress insertObject: state
                              atIndex: 0];
    }
    NSString *city = address[@"City"];
    if (city.length > 0) {
        [strippedAddress insertObject: city
                              atIndex: 0];
    }
    NSString *thoroughfare = address[@"Thoroughfare"];
    if (thoroughfare.length > 0) {
        [strippedAddress insertObject: thoroughfare
                              atIndex: 0];
    }

    NSString *rawDescription = [strippedAddress componentsJoinedByString: @", "];
    return rawDescription;
}

- (NSString *)currentLocationFullDescription
{
    return [self.currentAddressDictionary[@"FormattedAddressLines"]
            componentsJoinedByString: @", "];
}

- (NSString *)currentLocationCoordinatesString
{
    if (!self.currentLocation) {
        return NSLocalizedString(@"N/A,N/A", @"Unknown latitide and longitude");
    }
    return [self.currentLocation lr_coordinatesString];
}

@end
