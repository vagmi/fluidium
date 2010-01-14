//
//  NSObject-OFExtensions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "NSObject-OFExtensions.h"


@implementation NSObject (OFExtensions)

+ (NSBundle *)bundle {
    return [NSBundle bundleForClass:[self class]];
}

- (NSString *)shortDescription {
    return [self description];
}

@end
