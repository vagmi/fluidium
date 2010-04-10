//
//  TDFooBar.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDFooBar.h>
#import "TDFooBarListItem.h"

#define LIST_MARGIN_Y 2.0

@implementation TDFooBar

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {

    }
    return self;
}


- (void)dealloc {
    self.dataSource = nil;
    self.textField = nil;
    self.listView = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Bounds

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSRect bounds = [self bounds];
    
    [self.textField setFrame:[self textFieldRectForBounds:bounds]];
    [self.listView setFrame:[self listViewRectForBounds:bounds]];
}


- (NSRect)textFieldRectForBounds:(NSRect)bounds {
    return NSMakeRect(0, 0, bounds.size.width, bounds.size.height);
}


- (NSRect)listViewRectForBounds:(NSRect)bounds {
    return NSMakeRect(0, NSMaxY(bounds) + LIST_MARGIN_Y, bounds.size.width, NSHeight([listView frame]));
}


#pragma mark -
#pragma mark NSTextFieldNotifictions

- (void)textDidBeginEditing:(NSNotification *)n {
    [self.listView setHidden:YES];
    [self addSubview:self.listView];
}


- (void)textDidEndEditing:(NSNotification *)n {
    [self.listView removeFromSuperview];
}


- (void)textDidChange:(NSNotification *)n {
    [self.listView reloadData];
}

                            
#pragma mark -
#pragma mark TDListViewDataSource

- (NSUInteger)numberOfItemsInListView:(TDListView *)lv {
    NSAssert(dataSource, @"must provide a FooBarDataSource");
    return [dataSource numberOfItemsInFooBar:self];
}


- (TDListItem *)listView:(TDListView *)lv itemAtIndex:(NSUInteger)i {
    NSAssert(dataSource, @"must provide a FooBarDataSource");
    
    TDFooBarListItem *item = (TDFooBarListItem *)[listView dequeueReusableItemWithIdentifier:[TDFooBarListItem reuseIdentifier]];
    if (!item) {
        item = [[[TDFooBarListItem alloc] init] autorelease];
    }
    
    item.labelText = [dataSource fooBar:self objectAtIndex:i];
    
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
        [self addSubview:listView];
    }
    return listView;
}


@synthesize dataSource;
@synthesize textField;
@synthesize listView;
@end
