//
//  FooBarDemoAppDelegate.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "FooBarDemoAppDelegate.h"

@implementation FooBarDemoAppDelegate

- (void)awakeFromNib {
    [[window contentView] setWantsLayer:YES];
}

#pragma mark -
#pragma mark TDFooBarDataSource

- (NSUInteger)numberOfItemsInFooBar:(TDFooBar *)fb {
    return 5;
}


- (id)fooBar:(TDFooBar *)fb objectAtIndex:(NSUInteger)i {
    return [[NSNumber numberWithInt:i] stringValue];
}

@end
