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

#define DEFAULT_ROW_HEIGHT 44

@interface TDListView ()
@property (nonatomic, retain) NSMutableArray *visibleRowViews;
@property (nonatomic, retain) TDListItemViewQueue *rowViewQueue;
@end

@implementation TDListView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        //scrollView 
        
        self.backgroundColor = [NSColor whiteColor];
        self.rowHeight = DEFAULT_ROW_HEIGHT;
        
        self.rowViewQueue = [[[TDListItemViewQueue alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
    self.scrollView = nil;
    self.backgroundColor = nil;
    self.visibleRowViews = nil;
    self.rowViewQueue = nil;
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
    for (TDListItemView *rv in visibleRowViews) {
        if (NSPointInRect(p, [rv frame])) {
            clickedView = rv;
            break;
        }
        i++;
    }
    
    if (clickedView) {
        self.selectedRowIndex = i;
    }
}


- (void)viewWillDraw {
    [self layoutRows];
}


- (void)drawRect:(NSRect)dirtyRect {
    [backgroundColor set];
    NSRectFill(dirtyRect);
}


- (void)reloadData {
    [self setNeedsDisplay:YES];
}


- (id)dequeueReusableRowViewWithIdentifier:(NSString *)s {
    return [rowViewQueue dequeueWithIdentifier:s];
}


- (void)layoutRows {
    NSAssert(dataSource, @"TDListView must have a dataSource before doing layout");
    
    NSRect scrollBounds = [scrollView bounds];
    NSSize scrollContentSize = [scrollView contentSize];
    BOOL isVert = scrollContentSize.height > scrollContentSize.width;

    NSSize scrollSize = NSZeroSize;
    if (isVert) {
        scrollSize = NSMakeSize(scrollContentSize.width, scrollBounds.size.height);
    } else {
        scrollSize = NSMakeSize(scrollBounds.size.width, scrollContentSize.height);
    }
        
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = isVert ? scrollSize.width : 0;
    CGFloat h = isVert ? 0 : scrollSize.height;

    for (TDListItemView *rv in visibleRowViews) {
        [rowViewQueue enqueue:rv withIdentifier:[[rv class] identifier]];
        [rv removeFromSuperview];
    }
    
    NSInteger c = [dataSource numberOfRowsInTableView:self];
    self.visibleRowViews = [NSMutableArray arrayWithCapacity:c];

    NSInteger i = 0;
    for ( ; i < c; i++) {
        TDListItemView *rv = [dataSource tableView:self viewForRowAtIndex:i];
        NSAssert1(rv, @"nil rowView returned for index: %d", i);
        
        // get row height
        NSInteger wh = rowHeight;
        if (delegate && [delegate respondsToSelector:@selector(tableView:heightForRowAtIndex:)]) {
            wh = [delegate tableView:self heightForRowAtIndex:i];
        }        
        
        if (isVert) {
            h = wh;
        } else {
            w = wh;
        }
        
        [rv setFrame:NSMakeRect(x, y, w, h)];
        [rv setNeedsDisplay:YES];
        
        [self addSubview:rv];
        [visibleRowViews addObject:rv];
        
        if (isVert) {
            y += wh; // add height for next row
            //if (y > scrollSize.height) break;
        } else {
            x += wh;
            //if (x > scrollSize.width) break;
        }
    }
    
    NSRect frame = [self frame];
    if (isVert) {
        y = y < scrollSize.height ? scrollSize.height : y;
        frame.size.height = y;
    } else {
        x = x < scrollSize.width ? scrollSize.width : x;
        frame.size.width = x;
    }
    [self setFrame:frame];
}


- (void)setSelectedRowIndex:(NSInteger)i {
    if (i != selectedRowIndex) {
        if (delegate && [delegate respondsToSelector:@selector(tableView:willSelectRowAtIndex:)]) {
            if (-1 == [delegate tableView:self willSelectRowAtIndex:i]) {
                return;
            }
        }
        
        selectedRowIndex = i;
        [self reloadData];
        
        if (delegate && [delegate respondsToSelector:@selector(tableView:didSelectRowAtIndex:)]) {
            [delegate tableView:self didSelectRowAtIndex:i];
        }
    }
}

@synthesize scrollView;
@synthesize dataSource;
@synthesize delegate;
@synthesize backgroundColor;
@synthesize rowHeight;
@synthesize selectedRowIndex;
@synthesize visibleRowViews;
@synthesize rowViewQueue;
@end
