//
//  TDFooBarListView.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/10/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDFooBarListView.h"

@implementation TDFooBarListView

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];

    [[NSColor greenColor] set];
    NSRectFill(bounds);
}

@end
