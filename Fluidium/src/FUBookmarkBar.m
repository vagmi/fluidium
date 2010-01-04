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

#import "FUBookmarkBar.h"
#import "FUBookmarkBarButton.h"
#import "FUBookmarkButtonSeparator.h"
#import "FUBookmarkBarOverflowButton.h"
#import "FUBookmarkController.h"
#import "FUBookmarkWindowController.h"
#import "FUBookmark.h"
#import "FUBookmarkBarListItemView.h"
#import "FUDocumentController.h"
#import "FUWindowController.h"
#import "FUUtils.h"
#import "FUNotifications.h"
#import "NSPasteboard+FUAdditions.h"
#import "WebURLsWithTitles.h"
#import "WebIconDatabase.h"
#import "WebIconDatabase+FUAdditions.h"
#import <TDAppKit/TDBar.h>
#import <TDAppKit/TDListItemView.h>

//#define BUTTON_SPACING 4
//#define BUTTON_MARGIN_LEFT 2
//#define BUTTON_MAX_WIDTH 180
//#define SEPARATOR_MIN_X 3

@implementation FUBookmarkBar

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {        
        //self.overflowButton = [[[FUBookmarkBarOverflowButton alloc] init] autorelease];
        //[overflowButton setTarget:self];

        //self.separator = [[[FUBookmarkButtonSeparator alloc] init] autorelease];
                
        //[self setUpOverflowMenu];
    }
    return self;
}


- (void)dealloc {
//    self.separator = nil;
//    self.overflowButton = nil;
//    self.overflowMenu = nil;
    [super dealloc];
}


- (void)awakeFromNib {
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    //    [nc addObserver:self selector:@selector(bookmarksDidChange:) name:FUBookmarksDidChangeNotification object:nil];
//    [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:[self window]];
//    [nc addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:[self window]];    
}


- (BOOL)isOpaque {
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
//    [[NSColor clearColor] set];
//    NSRectFill(dirtyRect);
}


//- (void)otherMouseDown:(NSEvent *)evt {
//    NSPoint p = [self convertPointFromBase:evt.locationInWindow];
//    FUBookmarkBarButton *button = [self buttonAtX:p.x];
//    if (button) {
//        [self performActionForButton:button];
//    }
//    [super otherMouseDown:evt];
//}


//#pragma mark -
//#pragma mark Notifications
//
//- (void)windowDidBecomeMain:(NSNotification *)n {
//    [self setNeedsDisplay:YES];
//}
//
//
//- (void)windowDidResignMain:(NSNotification *)n {
//    [self setNeedsDisplay:YES];
//}
//
//

//
//- (void)setUpOverflowMenu {
//    self.overflowMenu = [[[NSMenu alloc] init] autorelease];
//    [overflowButton setMenu:overflowMenu];
//    
//    NSInteger buttonHeight = NSHeight([overflowButton frame]);
//    NSInteger viewHeight = NSHeight([self frame]);
//    NSInteger buttonWidth = NSWidth([overflowButton frame]);
//    NSInteger viewWidth = NSWidth([self frame]);
//    
//    NSInteger x = viewWidth - buttonWidth;
//    NSInteger y = (viewHeight - buttonHeight) / 2;
//    
//    [overflowButton setFrameOrigin:NSMakePoint(x ,y)];
//    [self addSubview:overflowButton];
//}

//@synthesize separator;
//@synthesize overflowButton;
//@synthesize overflowMenu;
@end
