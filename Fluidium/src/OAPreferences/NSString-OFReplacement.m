//
//  NSString-OFReplacement.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "NSString-OFReplacement.h"

@implementation NSString (OFReplacement)

- (NSString *)stringByRemovingPrefix:(NSString *)prefix;
{
    NSRange aRange;
    
    aRange = [self rangeOfString:prefix options:NSAnchoredSearch];
    if ((aRange.length == 0) || (aRange.location != 0))
        return [[self retain] autorelease];
    return [self substringFromIndex:aRange.location + aRange.length];
}

- (NSString *)stringByRemovingSuffix:(NSString *)suffix;
{
    if (![self hasSuffix:suffix])
        return [[self retain] autorelease];
    return [self substringToIndex:[self length] - [suffix length]];
}

@end