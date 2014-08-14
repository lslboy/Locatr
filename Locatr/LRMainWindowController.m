//
//  LRMainWindowController.m
//  Locatr
//
//  Created by Dmitry Rodionov on 31.07.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "LRMainWindowController.h"
#import "LRTitlebarAccessoryViewController.h"
#import "LRLocationNotifications.h"
#import "LRLocationDog.h"
#import "LRAppsListManager.h"

@interface LRMainWindowController ()
@end

@implementation LRMainWindowController

- (void)awakeFromNib
{
    /* Create a button for the window's title bar */
    [self setupTitlebarAccessoryView];
    /* Default location button values */
    [self.buttomLocationButton setTitle: NSLocalizedString(@"Unknown location",
                                                           @"Main window > Location button default titile")];
    [self.buttomLocationButton setToolTip: NSLocalizedString(@"Unable to determine your current location",
                                                             @"Main window > Location button default tooltip")];

    /* Subscribe to a location-did-change notification */
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(locationDidChange:)
                                                 name: LRLocationDidChangeNotification
                                               object: nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - UI Actions

- (IBAction)addApplicationToList: (id)sender
{
    static BOOL openPanelIsShown = NO;
    if (openPanelIsShown) {
        return;
    }
    openPanelIsShown = YES;

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setDelegate: self];
    [panel setTitle: NSLocalizedString(@"Choose one or more applications", @"Open panel > Title")];
    [panel setPrompt: NSLocalizedString(@"Add", "Open panel > OK button")];
    NSString *applicationsDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory,
                                                                          NSSystemDomainMask,
                                                                          YES)[0];
    [panel setDirectoryURL: [NSURL URLWithString: applicationsDirectory]];
    [panel setShowsHiddenFiles: NO];
    [panel setAllowsOtherFileTypes: NO];
    [panel setAllowedFileTypes: @[@"app"]];
    [panel setAllowsMultipleSelection: YES];
    [panel beginWithCompletionHandler: ^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self.appsListManager addApplicationsWithURL: panel.URLs];
        }
        openPanelIsShown = NO;
    }];
}

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url
{
    /* We can also check here if this application has a valid bundle */
    return  YES;
}


- (void)locationDidChange: (NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.buttomLocationButton setTitle:
         [[LRLocationDog sharedDog] currentLocationPrettyDescription]];
        [self.buttomLocationButton setToolTip:
         [[LRLocationDog sharedDog] currentLocationFullDescription]];
    });
}

- (void)setupTitlebarAccessoryView
{
    NSButton *toggleAddApplicationPopoverButton = ({
        NSButton *button = [[NSButton alloc] initWithFrame: NSMakeRect(0, 0, 23, 21)];
        [button.cell setControlSize: NSMiniControlSize];
        [button setButtonType: NSMomentaryChangeButton];
        [button setBezelStyle: NSRoundRectBezelStyle];
        [button setTitle: @""];
        [button setBordered: NO];
        [button setImage: [NSImage imageNamed: NSImageNameAddTemplate]];

        [button setTarget: self];
        [button setAction: @selector(addApplicationToList:)];
        button;
    });

    if (NSClassFromString(@"NSTitlebarAccessoryViewController")) {
        /* 10.10+, use new NSWindow API */
        LRTitlebarAccessoryViewController *accessoryViewController = [[LRTitlebarAccessoryViewController alloc] init];
        accessoryViewController.lr_view = toggleAddApplicationPopoverButton;
        accessoryViewController.layoutAttribute = NSLayoutAttributeRight;
        [self.window addTitlebarAccessoryViewController: accessoryViewController];
    } else {
        /* 10.9 and older, fallback to  NSWindowThemeView */
        NSRect accessoryViewRect = toggleAddApplicationPopoverButton.frame;
        NSView *windowThemeView = [self.window.contentView superview];

        NSRect newFrame = NSMakeRect(
                                     /* x */ windowThemeView.frame.size.width  - accessoryViewRect.size.width,
                                     /* y */ windowThemeView.frame.size.height - accessoryViewRect.size.height,
                                     accessoryViewRect.size.width,
                                     accessoryViewRect.size.height);

        [toggleAddApplicationPopoverButton setFrame: newFrame];
        [windowThemeView addSubview: toggleAddApplicationPopoverButton];
    }
}

@end
