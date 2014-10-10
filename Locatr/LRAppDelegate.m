//
//  LRAppDelegate.m
//  Locatr
//
//  Created by Dmitry Rodionov on 31.07.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "LRAppDelegate.h"
#import "LRAppsListManager.h"
#import "LRMainWindowController.h"


@implementation LRAppDelegate

#pragma mark - NSApplicationDelegate's

- (void)applicationDidFinishLaunching: (NSNotification *)notification
{
    /* Localize File menu items */
    NSMenuItem *fileMenu = [[NSApp menu] itemWithTitle: @"File"];
    NSMenuItem *addApplicationItem = [[fileMenu submenu] itemWithTitle: @"[add_app]"];
    addApplicationItem.title = NSLocalizedString(@"Add application…", @"MainMenu > File > Add application item");
    /* Localize Help menu items */
    NSMenuItem *helpMenu = [[NSApp menu] itemWithTitle: @"Help"];
    NSMenuItem *reportItem = [helpMenu.submenu itemWithTitle: @"[report_issue]"];
    NSMenuItem *suggestionItem = [helpMenu.submenu itemWithTitle: @"[send_suggestion]"];
    NSMenuItem *websiteItem = [helpMenu.submenu itemWithTitle: @"[open_locatr_website]"];

    reportItem.title = NSLocalizedString(@"Report an issue", @"MainMenu > Help > menu item");
    suggestionItem.title = NSLocalizedString(@"Send suggestion", @"MainMenu > Help > menu item");
    websiteItem.title = NSLocalizedString(@"Open Locatr website", @"MainMenu > Help > menu item");
}

- (NSMenu *)applicationDockMenu: (NSApplication *)sender
{
    NSMenu *dockMenu = [NSMenu new];
    /* Set new location (show main window and activate the location popover) */
    NSMenuItem *setNewLocation = [NSMenuItem new];
    setNewLocation.title = NSLocalizedString(@"Set new location…", @"Dock menu > menu item");
    setNewLocation.target = self.mainWindowController;
    setNewLocation.action = @selector(showWindowWithActivatedPopover:);
    [dockMenu addItem: setNewLocation];
    /* Restore original location state */
    NSMenuItem *restoreOriginalState = [NSMenuItem new];
    restoreOriginalState.title = NSLocalizedString(@"Restore original location", @"Dock menu > menu item");
    restoreOriginalState.target = self.mainWindowController.appsListManager;
    restoreOriginalState.action = @selector(disableAllLocationChanges:);
    [dockMenu addItem: restoreOriginalState];

    return dockMenu;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender
{
    return NO;
}

- (void)applicationWillTerminate: (NSNotification *)notification
{
    [self.mainWindowController.appsListManager disableAllLocationChanges: self];
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
