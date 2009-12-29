//
//  FUTabTableRowView.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "FUTabTableRowView.h"

@implementation FUTabTableRowView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}


- (void)dealloc {
    self.thumbnail = nil;
    self.title = nil;
    self.URLString = nil;
    [super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {
    NSRect rect = [self bounds];
    
    [[NSColor redColor] set];
    NSRectFill(rect);
    
    [[NSColor greenColor] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:1];
    [path moveToPoint:NSZeroPoint];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), 0)];
    [path stroke];
}

@synthesize thumbnail;
@synthesize title;
@synthesize URLString;
@end
