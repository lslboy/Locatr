//
//  LRLocationPopoverViewController.h
//  Locatr
//
//  Created by Dmitry Rodionov on 02.08.14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LRLocationPopoverViewController : NSViewController

@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSPopUpButton *popUpMenuButton;
@property (weak) IBOutlet NSProgressIndicator *indicator;
@property (weak) IBOutlet NSTextField *inputTextField;
@property (weak) IBOutlet NSTextField *errorTextField;

- (IBAction)togglePopover: (NSButton *)sender;
- (IBAction)lookupNewLocation: (id)sender;
- (IBAction)backToPreviousLocation: (id)sender;
- (IBAction)restoreOriginalLocation: (id)sender;

@end
