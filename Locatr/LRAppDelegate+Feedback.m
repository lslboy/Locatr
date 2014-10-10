//
//  LRAppDelegate+Feedback.m
//  Locatr
//
//  Created by Dmitry Rodionov on 10/10/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "LRAppDelegate+Feedback.h"

#define kMyEmail @"i.am.rodionovd@gmail.com"
#define kLocatrWebsiteURL @"http://rodionovd.github.io/locatrapp/"

@implementation LRAppDelegate (Feedback)

- (IBAction)reportIssue:(id)sender
{
    NSString *subject = [NSString stringWithFormat: @"Locatr (%@, build %@): new issue detected!",
                         [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]];

    NSString *body = @"Hello!\nI've came across an issue in Locatr. Here it is.\n\n"
    @"WHAT HAPPEND:\n{{ Provide a descriptive summary of the issue }}\n\n"
    @"WHY THIS BEHAVIOR IS WRONG:\n{{ Maybe it's a feature, not a bug? :) }}\n\n"
    @"STEPS TO REPRODUCE THE BUG:\n{{ In numbered format, detail the exact steps taken to produce the bug }}\n\n"
    @"NOTES:\n{{ Anything else about the issue }}\n\n";
    NSString *mailto = [[NSString stringWithFormat:
                         @"mailto:%@?subject=%@&body=%@", kMyEmail, subject, body]
                        stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: mailto]];
}

- (IBAction)sentFeatureRequest:(id)sender
{
    NSString *subject = [NSString stringWithFormat: @"Locatr (%@, build %@): I have a great idea!",
                         [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]];

    NSString *body = @"Hello!\nI have an idea about Locatr. Here is it:\n\n"
    @"{{ Please, describe you idea here. Thank you! (^,^) }}";
    NSString *mailto = [[NSString stringWithFormat:
                         @"mailto:%@?subject=%@&body=%@", kMyEmail, subject, body]
                        stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: mailto]];
}

- (IBAction)openLocatrWebsite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: kLocatrWebsiteURL]];
}

@end
