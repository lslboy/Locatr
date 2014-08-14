//
//  CLLocation+Description.m
//  Locatr
//
//  Created by Dmitry Rodionov on 8/3/14.
//  Copyright (c) 2014 rodionovd. All rights reserved.
//

#import "CLLocation+Description.h"

@implementation CLLocation (Description)

- (NSString *)lr_coordinatesString
{
    NSString *result = [NSString stringWithFormat: @"%.6lf, %.6lf",
                        self.coordinate.latitude,
                        self.coordinate.longitude];
    return result;
}

@end
