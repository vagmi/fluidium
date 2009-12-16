//
//  NSArray+FUAdditions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 6/12/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "NSArray+FUAdditions.h"

@implementation NSArray (FUAdditions)

- (NSMutableArray *)reversedMutableArray {
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:[self count]];
    for (id obj in [self reverseObjectEnumerator]) {
        [tmp addObject:obj];
    }
    return tmp;
}


- (NSArray *)reversedArray {
    return [[[self reversedMutableArray] copy] autorelease];
}

@end
