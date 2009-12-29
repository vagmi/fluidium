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
        
        self.rowViews = [NSMutableArray array];
        self.rowHeight = DEFAULT_ROW_HEIGHT;
    }
    return self;
}


- (void)dealloc {
    self.rowViews = nil;
    [super dealloc];
}


- (void)viewWillDraw {
    [self layoutRowViews];
}


- (void)drawRect:(NSRect)r {
    [super drawRect:r];
}


- (void)reloadData {
    
}


- (void)layoutRowViews {
    NSInteger i = 0;

    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = NSWidth([self frame]);
    CGFloat h = 0;
    
    for (TDTableRowView *rowView in rowViews) {
        
        // get row height
        h = rowHeight;
        if (delegate && [delegate respondsToSelector:@selector(tableView:heightForRowAtIndex:)]) {
            h = [delegate tableView:self heightForRowAtIndex:i];
        }
        
        [rowView setFrame:NSMakeRect(x, y, w, h)];
        [rowView setNeedsDisplay:YES];
        
        y += h; // add height for next row
    }
    
    [self setNeedsDisplay:YES];
}

@synthesize dataSource;
@synthesize delegate;
@synthesize orientation;
@synthesize rowHeight;
@synthesize scrollView;
@synthesize rowViews;
@end
