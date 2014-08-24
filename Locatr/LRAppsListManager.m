//
//  LTAppsListControlller.m
//  Locatr
//
//  Created by Dmitry Rodionov on 7/29/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//
#import "LRInjector.h"
#import "LRAppsListManager.h"
#import "LRApplicationModel.h"
#import "LRApplicationCellView.h"
#import "LRMenuEnabledTableView.h"

static char * const LRUserDefaultsOperationsQueueLabel = "Locatr.LRAppsListManager.userDefaultsOperations_queue";
static NSString * const LRApplicationsListDefaulsKey = @"LRApplicationsListDefaulsKey";

@interface LRAppsListManager()

@property (strong) NSMutableArray *applications; /// Items of class LTApplicationModel
@property (strong) NSLock *applicationsListAccessLock;
@property (strong) dispatch_queue_t userDefaultsOperationsQueue;

- (void)reloadApplicationsList;
- (void)saveApplicationsList;
@end

@implementation LRAppsListManager

- (instancetype)init
{
    if ((self = [super init])) {
        _applications = [NSMutableArray new];
        _applicationsListAccessLock = [NSLock new];
        _userDefaultsOperationsQueue = dispatch_queue_create(LRUserDefaultsOperationsQueueLabel,
                                                             DISPATCH_QUEUE_SERIAL);
        dispatch_sync(self.userDefaultsOperationsQueue, ^{
            //        [[NSUserDefaults standardUserDefaults] removeObjectForKey: LRApplicationsListDefaulsKey];
            //        [[NSUserDefaults standardUserDefaults] synchronize];
            [self reloadApplicationsList];
        });
    }

    return self;
}

- (void)dealloc
{
    [self.tableView setDelegate: nil];
}

- (void)awakeFromNib
{
    [self.tableView setMenuDelegate: self];
}

#pragma mark - Public interface

- (void)addApplicationsWithURL: (NSArray *)urls
{
    [self.applicationsListAccessLock lock];
    [urls enumerateObjectsUsingBlock: ^(NSURL *url, NSUInteger idx, BOOL *stop) {
        LRApplicationModel *model = [LRApplicationModel modelForApplicationAtURL: url];
        NSUInteger duplicateIdx = [self.applications indexOfObjectPassingTest:
                          ^BOOL(LRApplicationModel *obj, NSUInteger idx_internal, BOOL *stop_internal) {
            return [obj.bundleIdentifier isEqualToString: model.bundleIdentifier];
        }];
        if (duplicateIdx == NSNotFound) {
            [self.applications addObject: model];
        }
    }];
    [self.applicationsListAccessLock unlock];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    dispatch_async(self.userDefaultsOperationsQueue, ^{
        [self saveApplicationsList];
    });
}

- (void)disableAllLocationChanges
{
    [self saveApplicationsList];
    [self.applications enumerateObjectsUsingBlock: ^(LRApplicationModel *model, NSUInteger idx, BOOL *stop) {
        [[LRInjector sharedInjector] disableInjectionForApplication: model];
    }];
}

#pragma mark - UI Actions

- (IBAction)toggleSwitch: (id)sender
{
    LRApplicationCellView *view = (LRApplicationCellView *)[sender superview];
    LRApplicationModel *model = view.model;
    [(NSButton *)sender setEnabled: NO];

    switch (model.state) {
        case LRApplicationModelStateDisabled: {
            NSLog(@"Enable %@", model.title);
            [[LRInjector sharedInjector] enableInjectionForApplication: model completion:
             ^(NSError *error) {
                if (error) {
                    NSLog(@"ERROR ENABLING %@", model.bundleIdentifier);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [(NSButton *)sender setState: NSOffState];
                        [(NSButton *)sender setEnabled: YES];
                        [view updateSwitchButton];
                    });

                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [(NSButton *)sender setEnabled: YES];
                        [view updateSwitchButton];
                    });
                    dispatch_async(self->_userDefaultsOperationsQueue, ^{
                        [self saveApplicationsList];
                    });
                }
            }];
            break;
        }
        case LRApplicationModelStateEnabled: {
            NSLog(@"Disable %@", model.title);
            [[LRInjector sharedInjector] disableInjectionForApplication: model];
            dispatch_async(dispatch_get_main_queue(), ^{
                [(NSButton *)sender setEnabled: YES];
            });
            dispatch_async(self->_userDefaultsOperationsQueue, ^{
                [self saveApplicationsList];
            });
            break;
        }
        case LRApplicationModelStateError: {
            NSLog(@"Retry %@", model.title);
            dispatch_async(dispatch_get_main_queue(), ^{
                [(NSButton *)sender setEnabled: YES];
            });
            break;
        }
        default:
            return;
    }
}

#pragma mark - Saving and reading items

- (void)saveApplicationsList
{
    [self.applicationsListAccessLock lock];
    NSMutableArray *list = [NSMutableArray arrayWithCapacity: self.applications.count];
    [self.applications enumerateObjectsUsingBlock: ^(id model, NSUInteger idx, BOOL *stop) {
        NSData *entry = [NSKeyedArchiver archivedDataWithRootObject: model];
        [list addObject: entry];
    }];
    [[NSUserDefaults standardUserDefaults] setObject: list
                                              forKey: LRApplicationsListDefaulsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.applicationsListAccessLock unlock];
}

- (void)reloadApplicationsList
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSArray *list = [[NSUserDefaults standardUserDefaults]
                     objectForKey: LRApplicationsListDefaulsKey];
    if (list.count == 0) return;
    [self.applicationsListAccessLock lock];
    /* Clear the current list and reload all the items from the User Defaults*/
    [self.applications removeAllObjects];
    [list enumerateObjectsUsingBlock: ^(NSData *data, NSUInteger idx, BOOL *stop) {
        LRApplicationModel *model = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        if (!model) return;
        [self.applications addObject: model];
        if (model.state == LRApplicationModelStateEnabled) {
            [[LRInjector sharedInjector] enableInjectionForApplication: model
                                                            completion: nil];
        }
    }];
    [self.applicationsListAccessLock unlock];
}

#pragma mark - NSTableView Data Source's and Delegate's

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    [self.applicationsListAccessLock lock];
    NSUInteger count = self.applications.count;
    [self.applicationsListAccessLock unlock];

    return (NSInteger)count;
}

- (NSView *)tableView: (NSTableView *)tableView
   viewForTableColumn: (NSTableColumn *)tableColumn
                  row: (NSInteger)row
{
    LRApplicationCellView *view = [tableView makeViewWithIdentifier: [tableColumn identifier]
                                                              owner: self];
    [self.applicationsListAccessLock lock];
    LRApplicationModel *model = self.applications[(NSUInteger)row];
    [self.applicationsListAccessLock unlock];
    [view setModel: model];

    [view.checkbox setState: model.state];
    [view.imageView setImage: model.icon];
    [view.textField setStringValue: model.title];

    return view;
}

#pragma mark - LRMenuEnabledTableViewDelegate's

- (NSMenu *)rightMouseMenuForTableView: (LRMenuEnabledTableView *)tableView
                                column: (NSInteger)column
                                   row: (NSInteger)row
{
    [self.applicationsListAccessLock lock];
    NSUInteger count = self.applications.count;
    [self.applicationsListAccessLock unlock];
    if (count < (NSUInteger)row) {
        return nil;
    }
    NSMenu *menu = [NSMenu new];
    NSMenuItem *showInFinderItem = [[NSMenuItem alloc]
                                    initWithTitle:
                                    NSLocalizedString(@"Show in Finder",
                                                      @"Table View > Right-click menu item")
                                    action: @selector(showSelectedApplicationInFinder:)
                                    keyEquivalent: @""];
    [showInFinderItem setTarget: self];
    [showInFinderItem setRepresentedObject: @(row)];

    NSMenuItem *removeItem = [[NSMenuItem alloc]
                              initWithTitle:
                              NSLocalizedString(@"Remove from list",
                                                @"Table View > Left-click menu item")
                              action: @selector(removeSelectedApplicationFromList:)
                              keyEquivalent: @""];
    [removeItem setTarget: self];
    [removeItem setRepresentedObject: @(row)];

    [menu addItem: showInFinderItem];
    [menu addItem: [NSMenuItem separatorItem]];
    [menu addItem: removeItem];

    return menu;
}

- (void)showSelectedApplicationInFinder: (NSMenuItem *)sender
{
    NSInteger row = [[sender representedObject] integerValue];
    NSURL *itemURL = [(LRApplicationModel *)self.applications[(NSUInteger)row] URL];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs: @[itemURL]];
}

- (void)removeSelectedApplicationFromList: (NSMenuItem *)sender
{
    NSUInteger row = (NSUInteger)[[sender representedObject] integerValue];

    LRApplicationModel *model = self.applications[row];
    [[LRInjector sharedInjector] disableInjectionForApplication: model];

    [self.applicationsListAccessLock lock];
    [self.applications removeObject: model];
    [self.applicationsListAccessLock unlock];

    dispatch_async(self.userDefaultsOperationsQueue, ^{
        [self saveApplicationsList];
    });

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end
