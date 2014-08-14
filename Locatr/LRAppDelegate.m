//
//  LRAppDelegate.m
//  Locatr
//
//  Created by Dmitry Rodionov on 31.07.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "LRAppDelegate.h"
#import "LRMainWindowController.h"


@implementation LRAppDelegate

#pragma mark - NSApplicationDelegate's

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

- (void)applicationDidBecomeActive: (NSNotification *)notification
{
    [self.mainWindowController.window makeKeyAndOrderFront: self];
}

- (BOOL)applicationShouldHandleReopen: (NSApplication *)sender hasVisibleWindows: (BOOL)flag
{
    [self.mainWindowController.window makeKeyAndOrderFront: self];
    return YES;
}

@end
