//
//  TDFooBarListView.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/10/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDFooBarListView.h"
#import <NSBezierPath+TDAdditions.h>

@implementation TDFooBarListView

- (id)init {
    return [self initWithFrame:NSZeroRect];
}


- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setWantsLayer:YES];

        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(0, 10)];
        [shadow setShadowBlurRadius:10];
        [shadow setShadowColor:[NSColor blackColor]];
        
        //[self setShadow:shadow];
        [self setAlphaValue:.8];
    }
    return self;
}


- (void)dealloc {

    [super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];

    [[NSColor clearColor] setFill];
    NSRectFill(bounds);
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundRect:bounds radius:5.0];
    [[NSColor whiteColor] setFill];
    [path fill];
}

@end
