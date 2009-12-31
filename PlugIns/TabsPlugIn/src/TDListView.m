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

#import "TDListView.h"
#import "TDListItemView.h"
#import "TDListItemViewQueue.h"

#define DEFAULT_ITEM_HEIGHT 44

@interface TDListView ()
- (void)layoutItems;

@property (nonatomic, retain) NSMutableArray *visibleItemViews;
@property (nonatomic, retain) TDListItemViewQueue *itemViewQueue;
@end

@implementation TDListView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [NSColor whiteColor];
        self.itemHeight = DEFAULT_ITEM_HEIGHT;
        
        self.itemViewQueue = [[[TDListItemViewQueue alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
    self.scrollView = nil;
    self.backgroundColor = nil;
    self.visibleItemViews = nil;
    self.itemViewQueue = nil;
    [super dealloc];
}


- (BOOL)isFlipped {
    return YES;
}


- (BOOL)acceptsFirstResponder {
    return YES;
}


- (void)mouseDown:(NSEvent *)evt {
    [super mouseDown:evt];
    
    NSPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];
    
    TDListItemView *clickedView = nil;
    NSInteger i = 0;
    for (TDListItemView *rv in visibleItemViews) {
        if (NSPointInRect(p, [rv frame])) {
            clickedView = rv;
            break;
        }
        i++;
    }
    
    if (clickedView) {
        self.selectedItemIndex = i;
    }
}


- (void)viewWillDraw {
    [self layoutItems];
}


- (void)drawRect:(NSRect)dirtyRect {
    [backgroundColor set];
    NSRectFill(dirtyRect);
}


- (void)reloadData {
    [self setNeedsDisplay:YES];
}


- (id)dequeueReusableItemViewWithIdentifier:(NSString *)s {
    TDListItemView *itemView = [itemViewQueue dequeueWithIdentifier:s];
    [itemView prepareForReuse];
    return itemView;
}


- (void)layoutItems {
    NSAssert(dataSource, @"TDListView must have a dataSource before doing layout");
    
    NSRect scrollBounds = [scrollView bounds];
    NSSize scrollContentSize = [scrollView contentSize];
    BOOL isPortrait = TDListViewOrientationPortrait == orientation;

    NSSize scrollSize = NSZeroSize;
    if (isPortrait) {
        scrollSize = NSMakeSize(scrollContentSize.width, scrollBounds.size.height);
    } else {
        scrollSize = NSMakeSize(scrollBounds.size.width, scrollContentSize.height);
    }
        
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = isPortrait ? scrollSize.width : 0;
    CGFloat h = isPortrait ? 0 : scrollSize.height;

    for (TDListItemView *itemView in visibleItemViews) {
        [itemViewQueue enqueue:itemView withIdentifier:itemView.reuseIdentifier];
        [itemView removeFromSuperview];
    }
    
    NSInteger c = [dataSource numberOfItemsInListView:self];
    self.visibleItemViews = [NSMutableArray arrayWithCapacity:c];

    NSInteger i = 0;
    for ( ; i < c; i++) {
        TDListItemView *listItem = [dataSource listView:self viewForItemAtIndex:i];
        NSAssert1(listItem, @"nil rowView returned for index: %d", i);
        
        // get row height
        NSInteger wh = itemHeight;
        if (delegate && [delegate respondsToSelector:@selector(listView:heightForItemAtIndex:)]) {
            wh = [delegate listView:self heightForItemAtIndex:i];
        }        
        
        if (isPortrait) {
            h = wh;
        } else {
            w = wh;
        }
        
        [listItem setFrame:NSMakeRect(x, y, w, h)];
        [self addSubview:listItem];

        [visibleItemViews addObject:listItem];
        
        if (isPortrait) {
            y += wh; // add height for next row
            //if (y > scrollSize.height) break;
        } else {
            x += wh;
            //if (x > scrollSize.width) break;
        }
    }
    
    NSRect frame = [self frame];
    if (isPortrait) {
        y = y < scrollSize.height ? scrollSize.height : y;
        frame.size.height = y;
    } else {
        x = x < scrollSize.width ? scrollSize.width : x;
        frame.size.width = x;
    }
    [self setFrame:frame];
}


- (void)setSelectedItemIndex:(NSInteger)i {
    if (i != selectedItemIndex) {
        if (delegate && [delegate respondsToSelector:@selector(listView:willSelectRowAtIndex:)]) {
            if (-1 == [delegate listView:self willSelectRowAtIndex:i]) {
                return;
            }
        }
        
        selectedItemIndex = i;
        [self reloadData];
        
        if (delegate && [delegate respondsToSelector:@selector(listView:didSelectRowAtIndex:)]) {
            [delegate listView:self didSelectRowAtIndex:i];
        }
    }
}

@synthesize scrollView;
@synthesize dataSource;
@synthesize delegate;
@synthesize backgroundColor;
@synthesize itemHeight;
@synthesize selectedItemIndex;
@synthesize orientation;
@synthesize visibleItemViews;
@synthesize itemViewQueue;
@end
