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

#import "FUBrowsaBackgroundView.h"
#import "FUBrowsaPlugIn.h"
#import "FUBrowsaViewController.h"

#define MOUSE_MOVED_DETECTION_HEIGHT 60.0 

@interface FUBrowsaBackgroundView ()
- (void)startShowTimer;
- (void)startHideTimer;
@end
    
@implementation FUBrowsaBackgroundView

- (void)dealloc {
    self.viewController = nil;
    self.showTimer = nil;
    self.hideTimer = nil;
    [super dealloc];
}


- (void)drawRect:(NSRect)r {
    [[NSColor whiteColor] set];
    NSRectFill(r);
}


- (BOOL)acceptsFirstResponder {
    return YES;
}


- (void)mouseMoved:(NSEvent *)evt {
    [self setNeedsDisplay:YES];

    if (FUShowNavBarWhenMousedOver != viewController.plugIn.showNavBar) {
        return;
    }
    
    NSRect frame = [self frame];
    CGFloat h = MOUSE_MOVED_DETECTION_HEIGHT;
    NSRect r = NSMakeRect(0, NSMaxY(frame) - h, NSWidth(frame), h);
    NSPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];
    if (NSPointInRect(p, r)) {
        if (!showingNavBar) {
            showingNavBar = YES;
            [self startShowTimer];
        }
    } else {
        if (showingNavBar) {
            showingNavBar = NO;
            [showTimer invalidate];
            [self startHideTimer];
        }
    }
}


- (void)startShowTimer {
    self.showTimer = [NSTimer scheduledTimerWithTimeInterval:.25
                                                      target:self 
                                                    selector:@selector(showTimerFired:)
                                                    userInfo:nil 
                                                     repeats:NO];    
}


- (void)startHideTimer {
    self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:.4
                                                      target:self 
                                                    selector:@selector(hideTimerFired:)
                                                    userInfo:nil 
                                                     repeats:NO];    
}


- (void)showTimerFired:(NSTimer *)inTimer {
    [viewController showNavBar:self];
    [self setNeedsDisplay:YES];
}


- (void)hideTimerFired:(NSTimer *)inTimer {
    [viewController hideNavBar:self];
    [self setNeedsDisplay:YES];
}

@synthesize viewController;
@synthesize showTimer;
@synthesize hideTimer;
@end
