//
//  LTApplicationModel.m
//  Locatr
//
//  Created by Dmitry Rodionov on 7/29/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "LRApplicationModel.h"


@interface LRApplicationModel()
- (instancetype)initWithApplicationURL: (NSURL *)url state: (LRApplicationModelState)state;
@end

@implementation LRApplicationModel


- (instancetype)initWithApplicationURL: (NSURL *)url state: (LRApplicationModelState)state
{
    NSBundle *bundle = [NSBundle bundleWithURL: url];
    if (bundle.bundleIdentifier.length == 0) return nil;

    if ((self = [super init])) {
        _URL = url;
        _state = state;
        _bundleIdentifier = bundle.bundleIdentifier;
        /* Look up a localized application name */
        _title = [bundle objectForInfoDictionaryKey: @"CFBundleDisplayName"];
        if (!_title) {
            /* then a regular name */
            _title = [bundle objectForInfoDictionaryKey: @"CFBundleName"];
            if (!_title) {
                /* and fallback to a file name */
                _title = [[url.absoluteString lastPathComponent] stringByDeletingPathExtension];
            }
        }
        _icon = [[NSWorkspace sharedWorkspace] iconForFile: url.path];
    }

    return self;
}

+ (instancetype)modelForApplicationAtURL: (NSURL *)url;
{
    /* Disabled by default */
    return [[LRApplicationModel alloc] initWithApplicationURL: url
                                             state: LRApplicationModelStateDisabled];
}

#pragma mark - NSSecureCoding's

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder: (NSCoder *)decoder
{
    NSURL *url = [decoder decodeObjectOfClass: NSURL.class forKey: @"URL"];
    if (!url) return nil;
    LRApplicationModelState state = [decoder decodeIntegerForKey: @"state"];
    self = [self initWithApplicationURL: url state: state];

    return self;
}

- (void)encodeWithCoder: (NSCoder *)encoder
{
    [encoder encodeObject: self.URL forKey: @"URL"];
    [encoder encodeInteger: self.state forKey: @"state"];
}

@end
