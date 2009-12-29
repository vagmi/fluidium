//
//  FUTabsTableView.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "TDTableView.h"
#import "TDTableRowView.h"

#define DEFAULT_ROW_HEIGHT 44

@interface TDTableView ()
@property (nonatomic, retain) NSScrollView *scrollView;
@property (nonatomic, retain) NSMutableArray *rowViews;
@end

@implementation TDTableView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        //scrollView 
        
        self.backgroundColor = [NSColor whiteColor];
        self.rowHeight = DEFAULT_ROW_HEIGHT;
    }
    return self;
}


- (void)dealloc {
    self.backgroundColor = nil;
    self.rowViews = nil;
    [super dealloc];
}


- (BOOL)isFlipped {
    return YES;
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
    // TODO
    return nil;
}


- (void)layoutRows {
    NSAssert(dataSource, @"TDTableView must have a dataSource before doing layout");
    
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = NSWidth([self frame]);
    CGFloat h = 0;
    
    NSInteger i = 0;
    NSInteger c = [dataSource numberOfRowsInTableView:self];

    for (TDTableRowView *rv in rowViews) {
        [rv removeFromSuperview];
    }
    
    [[rowViews retain] autorelease]; // paranoia
    
    self.rowViews = [NSMutableArray arrayWithCapacity:c];

    for ( ; i < c; i++) {
        
        TDTableRowView *rv = [dataSource tableView:self viewForRowAtIndex:i];
        NSAssert1(rv, @"nil rowView returned for index: %d", i);
        
        // get row height
        h = rowHeight;
        if (delegate && [delegate respondsToSelector:@selector(tableView:heightForRowAtIndex:)]) {
            h = [delegate tableView:self heightForRowAtIndex:i];
        }
        
        [rv setFrame:NSMakeRect(x, y, w, h)];
        [rv setNeedsDisplay:YES];
        
        [self addSubview:rv];
        [rowViews addObject:rv];
        
        y += h; // add height for next row
    }
    
}

@synthesize dataSource;
@synthesize delegate;
@synthesize backgroundColor;
@synthesize orientation;
@synthesize rowHeight;
@synthesize selectedRowIndex;
@synthesize scrollView;
@synthesize rowViews;
@end
