//
//  TDFooBar.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDFooBar.h>
#import "TDFooBarListItem.h"

#define TEXT_MARGIN_X 5.0
#define TEXT_MARGIN_Y 5.0
#define LIST_MARGIN_Y 25.0

@implementation TDFooBar

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {

    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.dataSource = nil;
    self.textField = nil;
    self.listView = nil;
    [super dealloc];
}


- (BOOL)isFlipped {
    return YES;
}


#pragma mark -
#pragma mark Bounds

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    [self resizeSubviewsWithOldSize:NSZeroSize];
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSRect bounds = [self bounds];
    
    [self.textField setFrame:[self textFieldRectForBounds:bounds]];
    [self.listView setFrame:[self listViewRectForBounds:bounds]];
}


- (NSRect)textFieldRectForBounds:(NSRect)bounds {
    return NSMakeRect(TEXT_MARGIN_X, TEXT_MARGIN_Y, bounds.size.width - (TEXT_MARGIN_X * 2), 20);
}


- (NSRect)listViewRectForBounds:(NSRect)bounds {
    return NSMakeRect(0, LIST_MARGIN_Y, bounds.size.width, [TDFooBarListItem defaultHeight] * [self numberOfItemsInListView:listView]);
}


#pragma mark -
#pragma mark NSTextFieldNotifictions

- (void)controlTextDidBeginEditing:(NSNotification *)n {
    [[[self window] contentView] addSubview:self.listView];
    [self.listView setHidden:NO];
}


- (void)controlTextDidEndEditing:(NSNotification *)n {
    [self.listView removeFromSuperview];
}


- (void)controlTextDidChange:(NSNotification *)n {
    [self.listView reloadData];
}

                            
#pragma mark -
#pragma mark TDListViewDataSource

- (NSUInteger)numberOfItemsInListView:(TDListView *)lv {
    //NSAssert(dataSource, @"must provide a FooBarDataSource");
    return [dataSource numberOfItemsInFooBar:self];
}


- (TDListItem *)listView:(TDListView *)lv itemAtIndex:(NSUInteger)i {
    //NSAssert(dataSource, @"must provide a FooBarDataSource");
    
    TDFooBarListItem *item = (TDFooBarListItem *)[listView dequeueReusableItemWithIdentifier:[TDFooBarListItem reuseIdentifier]];
    if (!item) {
        item = [[[TDFooBarListItem alloc] init] autorelease];
    }
    
    item.labelText = [dataSource fooBar:self objectAtIndex:i];
    [item setNeedsDisplay:YES];
    
    return item;
}


#pragma mark -
#pragma mark TDListViewDelegate

- (CGFloat)listView:(TDListView *)lv extentForItemAtIndex:(NSUInteger)i {
    return [TDFooBarListItem defaultHeight];
}


- (void)listView:(TDListView *)lv willDisplayItem:(TDListItem *)item atIndex:(NSUInteger)i {
    
}


- (NSUInteger)listView:(TDListView *)lv willSelectItemAtIndex:(NSUInteger)i {
    return i;
}


- (void)listView:(TDListView *)lv didSelectItemAtIndex:(NSUInteger)i {
    
}


- (void)listView:(TDListView *)lv itemWasDoubleClickedAtIndex:(NSUInteger)i {
    
}


#pragma mark -
#pragma mark Properties

- (NSTextField *)textField {
    if (!textField) {
        NSRect r = [self textFieldRectForBounds:[self bounds]];
        self.textField = [[[NSTextField alloc] initWithFrame:r] autorelease];
        [textField setDelegate:self];
//        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//        [nc addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:textField];
//        [nc addObserver:self selector:@selector(textDidBeginEditing:) name:NSTextDidBeginEditingNotification object:textField];
//        [nc addObserver:self selector:@selector(textDidEndEditing:) name:NSTextDidEndEditingNotification object:textField];
        [self addSubview:textField];
    }
    return textField;
}


- (TDListView *)listView {
    if (!listView) {
        NSRect r = [self listViewRectForBounds:[self bounds]];
        self.listView = [[[TDListView alloc] initWithFrame:r] autorelease];
        listView.dataSource = self;
        listView.delegate = self;
    }
    return listView;
}


@synthesize dataSource;
@synthesize textField;
@synthesize listView;
@end
