//
//  NSBundle-OAExtensions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/14/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "NSBundle-OAExtensions.h"

@implementation NSBundle (OAExtensions)

- (void)loadNibNamed:(NSString *)nibName owner:(id <NSObject>)owner;
{
    NSMutableDictionary *ownerDictionary;
    BOOL successfulLoad;
    
    ownerDictionary = [[NSMutableDictionary alloc] init];
    [ownerDictionary setObject:owner forKey:@"NSOwner"];
    successfulLoad = [self loadNibFile:nibName externalNameTable:ownerDictionary withZone:[owner zone]];
    [ownerDictionary release];
    if (!successfulLoad)
        [NSException raise:NSInternalInconsistencyException format:@"Unable to load nib %@", nibName];
}

@end

