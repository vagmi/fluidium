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

#import <TDAppKit/TDListView.h>
#import <TDAppKit/TDListItemView.h>
#import "TDListItemViewQueue.h"

#define DEFAULT_ITEM_EXTENT 44

@interface TDListItemView ()
@property (nonatomic) NSUInteger index;
@end

@interface TDListView ()
- (void)layoutItems;
- (void)viewBoundsDidChange:(NSNotification *)n;

//@property (nonatomic, retain) NSMutableArray *itemViews;
@property (nonatomic, retain) TDListItemViewQueue *queue;
@end

@implementation TDListView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [NSColor whiteColor];
        self.itemExtent = DEFAULT_ITEM_EXTENT;
        
        self.queue = [[[TDListItemViewQueue alloc] init] autorelease];
        
        [self setPostsFrameChangedNotifications:YES];
        [self setPostsBoundsChangedNotifications:YES];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        //[nc addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self];
        [nc addObserver:self selector:@selector(viewBoundsDidChange:) name:NSViewFrameDidChangeNotification object:self];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.scrollView = nil;
    self.backgroundColor = nil;
    //    self.itemViews = nil;
    self.queue = nil;
    [super dealloc];
}


//- (void)viewFrameDidChange:(NSNotification *)n {
//
//}


- (void)viewBoundsDidChange:(NSNotification *)n {
    //    [self layoutItems];
}


#pragma mark -
#pragma mark Public

- (void)reloadData {
    //    [self layoutItems];
    [self setNeedsDisplay:YES];
}


- (id)dequeueReusableItemWithIdentifier:(NSString *)s {
    TDListItemView *itemView = [queue dequeueWithIdentifier:s];
    [itemView prepareForReuse];
    return itemView;
}


- (NSInteger)indexForItemAtPoint:(NSPoint)p {
    NSInteger i = 0;
    for (TDListItemView *itemView in [queue allObjects]) {
        if (NSPointInRect(p, [itemView frame])) {
            return i;
        }
        i++;
    }
    return NSNotFound;
}


- (id)viewForItemAtIndex:(NSInteger)i {
    id result = nil;
    
    for (TDListItemView *itemView in [queue allObjects]) {
        i == itemView.index;
        result = itemView;
        break;
    }
    
    return result;
}


#pragma mark -
#pragma mark NSView

- (BOOL)isFlipped {
    return YES;
}


- (BOOL)acceptsFirstResponder {
    return YES;
}


- (void)mouseDown:(NSEvent *)evt {
    [super mouseDown:evt];
    
    NSPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];
    
    NSInteger i = [self indexForItemAtPoint:p];
    if (NSNotFound == i) {
        if ([evt clickCount] > 1) {
            if (delegate && [delegate respondsToSelector:@selector(listView:emptyAreaWasDoubleClicked:)]) {
                [delegate listView:self emptyAreaWasDoubleClicked:evt];
            }
        }
    } else {
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


#pragma mark -
#pragma mark Public

- (void)setSelectedItemIndex:(NSInteger)i {
    if (i != selectedItemIndex) {
        if (delegate && [delegate respondsToSelector:@selector(listView:willSelectItemAtIndex:)]) {
            if (-1 == [delegate listView:self willSelectItemAtIndex:i]) {
                return;
            }
        }
        
        selectedItemIndex = i;
        [self reloadData];
        
        if (delegate && [delegate respondsToSelector:@selector(listView:didSelectItemAtIndex:)]) {
            [delegate listView:self didSelectItemAtIndex:i];
        }
    }
}


- (BOOL)isPortrait {
    return TDListViewOrientationPortrait == orientation;
}


- (BOOL)landscape {
    return TDListViewOrientationLandscape == orientation;
}


#pragma mark -
#pragma mark Private

- (NSRect)visibleRect {
    return [[scrollView contentView] bounds];
}


- (void)layoutItems {
    NSAssert(dataSource, @"TDListView must have a dataSource before doing layout");

    NSEnumerator *e = [[self subviews] reverseObjectEnumerator];
    TDListItemView *itemView = nil;
    while (itemView = [e nextObject]) {
        [queue enqueue:itemView];
        [itemView removeFromSuperview];
    }
    
    NSSize scrollContentSize = [scrollView contentSize];
    BOOL isPortrait = self.isPortrait;
    
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = isPortrait ? scrollContentSize.width : 0;
    CGFloat h = isPortrait ? 0 : scrollContentSize.height;
    
    NSInteger c = [dataSource numberOfItemsInListView:self];
    BOOL respondsToExtentForItem = (delegate && [delegate respondsToSelector:@selector(listView:extentForItemAtIndex:)]);
    NSRect viewportRect = [self visibleRect];
    
    NSInteger i = 0;
    for ( ; i < c; i++) {
        // determine item frame
        NSInteger extent = respondsToExtentForItem ? [delegate listView:self extentForItemAtIndex:i] : itemExtent;
        if (isPortrait) {
            h = extent;
        } else {
            w = extent;
        }
        NSRect itemFrame = NSMakeRect(x, y, w, h);
        
        if (NSIntersectsRect(viewportRect, itemFrame)) {
            TDListItemView *itemView = [dataSource listView:self viewForItemAtIndex:i];
            NSAssert1(itemView, @"nil rowView returned for index: %d", i);
            [itemView setFrame:NSMakeRect(x, y, w, h)];
            itemView.index = i;            
            [self addSubview:itemView];
        }

        if (isPortrait) {
            y += extent; // add height for next row
        } else {
            x += extent;
        }
    }
    
    NSRect frame = [self frame];
    if (isPortrait) {
        y = y < scrollContentSize.height ? scrollContentSize.height : y;
        frame.size.height = y;
    } else {
        x = x < scrollContentSize.width ? scrollContentSize.width : x;
        frame.size.width = x;
    }
    [self setFrame:frame];
    
    //NSLog(@"%s frame: %@, bounds: %@", _cmd, NSStringFromRect([self frame]), NSStringFromRect([self bounds]));
    //NSLog(@"%s my bounds: %@, viewport bounds: %@", _cmd, NSStringFromRect([self bounds]), NSStringFromRect([[scrollView contentView] bounds]));
    //NSLog(@"queue count: %d", [queue count]);
    //NSLog(@"view count: %d", [[self subviews] count]);
}

@synthesize scrollView;
@synthesize dataSource;
@synthesize delegate;
@synthesize backgroundColor;
@synthesize itemExtent;
@synthesize selectedItemIndex;
@synthesize orientation;
//@synthesize itemViews;
@synthesize queue;
@end
