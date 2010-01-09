//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "TDUberViewSplitView.h"
#import "TDUberView.h"

@interface TDUberViewSplitView ()
- (void)drawLeftDividerInRect:(NSRect)divRect;
- (void)drawRightDividerInRect:(NSRect)divRect;
@end

@implementation TDUberViewSplitView

- (id)initWithFrame:(NSRect)frame uberView:(TDUberView *)uv {
    if (self = [super initWithFrame:frame]) {
        self.uberView = uv;
        self.borderColor = [NSColor colorWithDeviceWhite:.4 alpha:1];
    }
    return self;
}


- (void)dealloc {
    self.uberView = nil;
    self.gradient = nil;
    self.borderColor = nil;
    [super dealloc];
}


- (BOOL)isFlipped {
    return YES;
}


- (CGFloat)dividerThickness {
    CGFloat result = [super dividerThickness];

    if (NSSplitViewDividerStyleThick == [uberView splitViewDividerStyle]) {
        if (result > 2) {
            result -= 2;
        }
    }
    
    return result;
}


- (void)drawDividerInRect:(NSRect)divRect {
    if (NSSplitViewDividerStyleThin == [uberView splitViewDividerStyle]) {
        [super drawDividerInRect:divRect]; 
        return;
    }
    
    BOOL isVert = self.isVertical;

    if (isVert) {
        // blend the vert and horiz dividers together
        BOOL isLeft = NSMinX(divRect) <= NSMaxX([uberView.leftView frame]);
        if (isLeft && uberView.isLeftViewOpen) {
            [self.gradient drawInRect:divRect angle:0];
            [self drawLeftDividerInRect:divRect];
        } else if (uberView.isRightViewOpen) {
            [self.gradient drawInRect:divRect angle:180];
            [self drawRightDividerInRect:divRect];
        }
    } else {
        BOOL isTop = NSMinY(divRect) <= NSMaxY([uberView.midView frame]);
        if ((isTop && uberView.isTopViewOpen) || (!isTop && uberView.isBottomViewOpen)) {

            [self.gradient drawInRect:divRect angle:90];
            [borderColor set];
            
            NSRect borderRect = NSOffsetRect(divRect, -1, 0);
            borderRect.size.width += 2;
            
            [NSBezierPath strokeRect:borderRect];
            
            //        // cover up rendering glitch
            //        borderRect = NSOffsetRect(divRect, -1, -.5);
            //        borderRect.size.width += 2;
            //        borderRect.size.height += 1;
            //        [[NSColor whiteColor] set];
            //        [NSBezierPath strokeRect:borderRect];
        }
    }
}


- (NSGradient *)gradient {
    if (!gradient) {
        NSColor *startColor = nil;
        NSColor *endColor = nil;
        
        if (self.isVertical) {
            startColor = [NSColor colorWithDeviceWhite:.95 alpha:1];
            endColor = [NSColor colorWithDeviceWhite:.80 alpha:1];
        } else {
            startColor = [NSColor colorWithDeviceWhite:.86 alpha:1];
            endColor = [NSColor colorWithDeviceWhite:.83 alpha:1];
        }
        self.gradient = [[[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor] autorelease];
    }
    return gradient;    
}


#pragma mark -
#pragma mark Private

- (void)drawLeftDividerInRect:(NSRect)divRect {
    CGFloat divThickness = [self dividerThickness];

    NSRect borderRect = NSOffsetRect(divRect, 0, -1);
    borderRect.size.height += 2;
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMaxX(borderRect), NSMinY(borderRect))];
    
    CGFloat topHeight = 0;
    BOOL isTopViewOpen = uberView.isTopViewOpen;
    if (isTopViewOpen) {
        topHeight = NSHeight([uberView.topView frame]);
        [path lineToPoint:NSMakePoint(NSMaxX(borderRect), topHeight)];
        [path moveToPoint:NSMakePoint(NSMaxX(borderRect), topHeight + divThickness)];
    }
    
    if (uberView.isBottomViewOpen) {
        CGFloat y = topHeight + NSMaxY([uberView.midView frame]) + (isTopViewOpen ? divThickness : 0);
        [path lineToPoint:NSMakePoint(NSMaxX(borderRect), y)];
        [path moveToPoint:NSMakePoint(NSMaxX(borderRect), y + divThickness)];
    }
    
    [path lineToPoint:NSMakePoint(NSMaxX(borderRect), NSMaxY(borderRect))];
    [path moveToPoint:NSMakePoint(NSMinX(borderRect), NSMaxY(borderRect))];
    [path lineToPoint:NSMakePoint(NSMinX(borderRect), NSMinY(borderRect))];
    
    [borderColor setStroke];
    [path stroke];
}


- (void)drawRightDividerInRect:(NSRect)divRect {
    CGFloat divThickness = [self dividerThickness];
    
    NSRect borderRect = NSOffsetRect(divRect, 0, -1);
    borderRect.size.height += 2;
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMinX(borderRect), NSMinY(borderRect))];
    
    CGFloat topHeight = 0;
    BOOL isTopViewOpen = uberView.isTopViewOpen;
    if (isTopViewOpen) {
        topHeight = NSHeight([uberView.topView frame]);
        [path lineToPoint:NSMakePoint(NSMinX(borderRect), topHeight)];
        [path moveToPoint:NSMakePoint(NSMinX(borderRect), topHeight + divThickness)];
    }
    
    if (uberView.isBottomViewOpen) {
        CGFloat y = topHeight + NSMaxY([uberView.midView frame]) + (isTopViewOpen ? divThickness : 0);
        [path lineToPoint:NSMakePoint(NSMinX(borderRect), y)];
        [path moveToPoint:NSMakePoint(NSMinX(borderRect), y + divThickness)];
    }
    
    [path lineToPoint:NSMakePoint(NSMinX(borderRect), NSMaxY(borderRect))];
    [path moveToPoint:NSMakePoint(NSMaxX(borderRect), NSMaxY(borderRect))];
    [path lineToPoint:NSMakePoint(NSMaxX(borderRect), NSMinY(borderRect))];
    
    [borderColor setStroke];
    [path stroke];
}

@synthesize uberView;
@synthesize borderColor;
@synthesize gradient;
@end
