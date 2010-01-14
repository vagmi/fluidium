//
//  NSString-OFSimpleMatching.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "NSString-OFSimpleMatching.h"

@implementation NSString (OFSimpleMatching)

+ (BOOL)isEmptyString:(NSString *)string;
// Returns YES if the string is nil or equal to @""
{
    // Note that [string length] == 0 can be false when [string isEqualToString:@""] is true, because these are Unicode strings.
    return string == nil || [string isEqualToString:@""];
}

@end
