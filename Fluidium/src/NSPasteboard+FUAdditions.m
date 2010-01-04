//
//  NSPasteboard+FUAdditions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/22/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "NSPasteboard+FUAdditions.h"
#import "WebURLsWithTitles.h"

@implementation NSPasteboard (FUAdditions)

- (BOOL)hasURLs {
    return ([self hasWebURLs] || [[self types] containsObject:NSURLPboardType]);
}


- (BOOL)hasWebURLs {
    return [[self types] containsObject:WebURLsWithTitlesPboardType];
}


- (BOOL)hasTypeFromArray:(NSArray *)types {
    BOOL foundType = NO;

    for (id type in types) {
        if ([[self types] containsObject:type]) {
            foundType = YES;
            break;
        }
    }
    
    return foundType;
}

@end
