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

#import "CRMoreListItem.h"

#define BUTTON_X 20
#define BUTTON_Y 14
#define BUTTON_HEIGHT 10

#define DEFAULT_HEIGHT 50

static NSGradient *sBackgroundGradient = nil;
static NSColor *sBorderBottomColor = nil;

@implementation CRMoreListItem

+ (void)initialize {
    if (self == [CRMoreListItem class]) {
        
        NSColor *topColor = [NSColor colorWithDeviceRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1];
        NSColor *botColor = [NSColor colorWithDeviceRed:233.0/255.0 green:233.0/255.0 blue:233.0/255.0 alpha:1];
        sBackgroundGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:botColor];

        sBorderBottomColor = [[NSColor colorWithDeviceRed:192.0/255.0 green:192.0/255.0 blue:192.0/255.0 alpha:1] retain];

    }
}


+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self);
}


+ (CGFloat)defaultHeight {
    return DEFAULT_HEIGHT;
}


- (id)init {
    return [self initWithFrame:NSZeroRect reuseIdentifier:[CRMoreListItem reuseIdentifier]];;
}


- (id)initWithFrame:(NSRect)frame reuseIdentifier:(NSString *)s {
    if (self = [super initWithFrame:frame reuseIdentifier:s]) {
        self.moreButton = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
        [moreButton setButtonType:NSMomentaryPushInButton];
        [moreButton setBezelStyle:NSRoundRectBezelStyle];
        [moreButton setTitle:NSLocalizedString(@"More", @"")];
        [moreButton sizeToFit];
        [self addSubview:moreButton];
    }
    return self;
}


- (void)dealloc {
    self.moreButton = nil;
    [super dealloc];
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSRect bounds = [self bounds];
    
    CGFloat height = NSHeight([moreButton frame]);
    [moreButton setFrame:NSMakeRect(BUTTON_X, BUTTON_Y, bounds.size.width - (BUTTON_X *2), height)];
}


- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
    
    // bg
    [sBackgroundGradient drawInRect:bounds angle:90];
    
    // border
    [sBorderBottomColor setStroke];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, bounds.size.height) toPoint:NSMakePoint(bounds.size.width, bounds.size.height)];
}

@synthesize moreButton;
@end
