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

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    /* Localize Main Menu custom items */
    NSMenuItem *fileMenu = [[NSApp menu] itemWithTitle: @"File"];
    NSMenuItem *addApplicationItem = [[fileMenu submenu] itemWithTitle: @"[add_app]"];
    if (addApplicationItem) {
        [addApplicationItem setTitle: NSLocalizedString(@"Add application…",
                                                        @"MainMenu > File > Add application item")];
    }
}

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
