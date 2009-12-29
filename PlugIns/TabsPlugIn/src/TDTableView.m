//
//  FUTabsTableView.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "TDTableView.h"
#import "TDTableRowView.h"
#import "TDTableRowViewQueue.h"

#define DEFAULT_ROW_HEIGHT 44

@interface TDTableView ()
@property (nonatomic, retain) NSScrollView *scrollView;
@property (nonatomic, retain) NSMutableArray *visibleRowViews;
@property (nonatomic, retain) TDTableRowViewQueue *rowViewQueue;
@end

@implementation TDTableView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        //scrollView 
        
        self.backgroundColor = [NSColor whiteColor];
        self.rowHeight = DEFAULT_ROW_HEIGHT;
        
        self.rowViewQueue = [[[TDTableRowViewQueue alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
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
    
    TDTableRowView *clickedView = nil;
    NSInteger i = 0;
    for (TDTableRowView *rv in visibleRowViews) {
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
    NSAssert(dataSource, @"TDTableView must have a dataSource before doing layout");
    
    NSRect bounds = [self bounds];
    
    BOOL isVert = bounds.size.height > bounds.size.width;
    
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = isVert ? bounds.size.width : 0;
    CGFloat h = isVert ? 0 : bounds.size.height;
    
    NSInteger i = 0;
    NSInteger c = [dataSource numberOfRowsInTableView:self];

    for (TDTableRowView *rv in visibleRowViews) {
        [rowViewQueue enqueue:rv withIdentifier:[[rv class] identifier]];
        [rv removeFromSuperview];
    }
    
    self.visibleRowViews = [NSMutableArray arrayWithCapacity:c];

    for ( ; i < c; i++) {
        TDTableRowView *rv = [dataSource tableView:self viewForRowAtIndex:i];
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
            if (y > bounds.size.height) break;
        } else {
            x += wh;
            if (x > bounds.size.width) break;
        }
    }
    
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

@synthesize dataSource;
@synthesize delegate;
@synthesize backgroundColor;
@synthesize rowHeight;
@synthesize selectedRowIndex;
@synthesize scrollView;
@synthesize visibleRowViews;
@synthesize rowViewQueue;
@end
