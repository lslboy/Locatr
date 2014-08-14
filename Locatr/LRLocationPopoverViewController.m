//
//  LRLocationPopoverViewController.m
//  Locatr
//
//  Created by Dmitry Rodionov on 02.08.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//
#include <CoreLocation/CLError.h>
#import "LRLocationPopoverViewController.h"
#import "LRLocationDog.h"

@interface LRLocationPopoverViewController ()
@end

@implementation LRLocationPopoverViewController

- (instancetype)init
{
    if ((self = [super init])) {
        
    }

    return self;
}

- (void)awakeFromNib
{
    /* Force using Light Content appearance for the popover */
    [self fixNSPopoverWindowAppearance];
    /* Check availability of Location Services and disable action elements
     * if it's not enabled */
    __weak typeof(self) welf = self;
    [[LRLocationDog sharedDog] setLocationServicesAuthStatusDidChangeCallback:
     ^(BOOL enabled) {
         __strong typeof(welf) strongSelf = welf;
         dispatch_async(dispatch_get_main_queue(), ^{
             if (enabled) {
                 [strongSelf.errorTextField setHidden: YES];
                 [strongSelf.inputTextField setEnabled: YES];
             } else {
                 [strongSelf.errorTextField setHidden: NO];
                 [strongSelf.inputTextField setEnabled: NO];
                 [strongSelf.popUpMenuButton setEnabled: NO];
                 [strongSelf.errorTextField setStringValue:
                  NSLocalizedString(@"Please, enable Location Services",
                                    @"Change location popover > Error message")];
             }
         });
     }];
    /* Localize the address text field' placeholder */
    [self.inputTextField.cell setPlaceholderString:
     NSLocalizedString(@"Madrid, Spain",
                       @"Change location popover > Input text field palceholder")];
    /* Localize the pop up menu items */
    NSMenu *menu = [self.popUpMenuButton menu];
    [menu.itemArray enumerateObjectsUsingBlock:
     ^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
         if ([item.title isEqualToString: @"[back]"]) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 item.title = NSLocalizedString(@"Back to previous location",
                                                @"Change location popover > Pop up menu item");
             });
             item.representedObject = @"[back]";
         }
         if ([item.title isEqualToString: @"[restore]"]) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 item.title = NSLocalizedString(@"Restore original location",
                                                @"Change location popover > Pop up menu item");
             });
             item.representedObject = @"[restore]";
         }
     }];
}

/**
 * For some reasons, NSPopover's window uses NSAquaAppearence and we can't change this.
 * I mean, we can actually :)
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)fixNSPopoverWindowAppearance
{
    [self.popover performSelector: NSSelectorFromString(@"_makePopoverWindowIfNeeded")];
    NSWindow *popoverWindow = [self.popover performSelector:
                               NSSelectorFromString(@"_popoverWindow")];
    [popoverWindow setAppearance: [NSAppearance appearanceNamed: NSAppearanceNameLightContent]];
}
#pragma clang diagnostic pop

- (void)verifyBackToPreviousLocationButton
{
    /* Enable or disable the "back to previous location" button */
    NSMenu *menu = [self.popUpMenuButton menu];
    [menu.itemArray enumerateObjectsUsingBlock: ^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
        if ([item.representedObject isEqualToString: @"[back]"]) {
            BOOL enabled = [[LRLocationDog sharedDog] canRollbackToPreviousLocation];
            dispatch_async(dispatch_get_main_queue(), ^{
                [item setEnabled: enabled];
            });
        }
    }];
}

- (IBAction)togglePopover: (NSButton *)sender
{
    if (self.popover.isShown) {
        [self.popover performClose: self];
    } else {
        [self.popover showRelativeToRect: sender.frame ofView: sender preferredEdge: NSMinYEdge];
    }

    [self verifyBackToPreviousLocationButton];
}

- (IBAction)lookupNewLocation: (NSTextField *)sender
{
    NSString *queue = [[sender stringValue] stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [sender setStringValue: queue];
    if (queue.length == 0) {
        return;
    }

    [self.errorTextField setHidden: YES];
    [self.inputTextField setEditable: NO];
    [self.popUpMenuButton setEnabled: NO];
    [self.indicator startAnimation: self];

    [[LRLocationDog sharedDog] updateLocationWithQueue: queue
                                               success:
     ^{
         dispatch_async(dispatch_get_main_queue(), ^{
             [self.inputTextField setEditable: YES];
             [self.popUpMenuButton setEnabled: YES];
             [self.indicator stopAnimation: self];
             [self.popover performClose: self];
         });
     } failrue: ^(NSError *error) {
         dispatch_async(dispatch_get_main_queue(), ^{
             if (error.code == kCLErrorNetwork) {
                 [self.errorTextField setStringValue:
                  NSLocalizedString(@"Please check your internet connection",
                                    @"Change location popover > Error message")];
             } else {
                 [self.errorTextField setStringValue:
                  NSLocalizedString(@"Invalid address, pick other one",
                                    @"Change location popover > Error message")];
             }
             [self.errorTextField setHidden: NO];
             [self.inputTextField setEditable: YES];
             [self.popUpMenuButton setEnabled: YES];
             [self.indicator stopAnimation: self];
         });
     }];
}

- (IBAction)backToPreviousLocation: (id)sender
{
    [self.errorTextField setHidden: YES];
    [self.inputTextField setEditable: NO];
    [self.indicator startAnimation: self];

    [[LRLocationDog sharedDog] rollbackToPreviousLocationWithSuccess: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.inputTextField setEditable: YES];
            [self.indicator stopAnimation: self];
            [self.popover performClose: self];
            [self verifyBackToPreviousLocationButton];
        });

    } failure: ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.errorTextField setStringValue:
             NSLocalizedString(@"Could not rollback to previous location",
                               @"Change location popover > Error message")];
            [self.errorTextField setHidden: NO];
            [self.inputTextField setEditable: YES];
            [self.indicator stopAnimation: self];
            [self verifyBackToPreviousLocationButton];
        });
    }];
}

- (IBAction)restoreOriginalLocation: (id)sender
{
    [self.errorTextField setHidden: YES];
    [self.inputTextField setEditable: NO];
    [self.indicator startAnimation: self];

    [[LRLocationDog sharedDog] restoreOriginalLocationWithSuccess: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.inputTextField setEditable: YES];
            [self.indicator stopAnimation: self];
            [self.popover performClose: self];
        });

    } failure: ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.errorTextField setStringValue:
             NSLocalizedString(@"Could not restore original location",
                               @"Change location popover > Error message")];
            [self.errorTextField setHidden: NO];
            [self.inputTextField setEditable: YES];
            [self.indicator stopAnimation: self];
        });
    }];
}

@end
