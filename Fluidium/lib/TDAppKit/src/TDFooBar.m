//
//  TDFooBar.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDFooBar.h>
#import <TDAppKit/TDListItem.h>
#import "TDFooBarTextField.h"
#import "TDFooBarListView.h"
#import "TDFooBarListItem.h"

#define TEXT_MARGIN_X 20.0
#define TEXT_MARGIN_Y 5.0
#define LIST_MARGIN_X 20.0
#define LIST_MARGIN_Y -5.0

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
    CGFloat listHeight = 30; //[TDFooBarListItem defaultHeight] * [self numberOfItemsInListView:listView];
    return NSMakeRect(LIST_MARGIN_X, NSMaxY([self frame]) + LIST_MARGIN_Y, bounds.size.width - (LIST_MARGIN_X * 2), listHeight);
}


#pragma mark -
#pragma mark NSResponder

- (void)moveUp:(id)sender {
    NSUInteger i = listView.selectedItemIndex;
    if (i <= 0 || NSNotFound == i) {
        i = 0;
    } else {
        i--;
    }
    listView.selectedItemIndex = i;
    [listView reloadData];
}


- (void)moveDown:(id)sender {
    NSUInteger i = listView.selectedItemIndex;
    NSUInteger last = [self numberOfItemsInListView:listView] - 1;
    if (i < last) {
        i++;
    }
    listView.selectedItemIndex = i;
    [listView reloadData];
}


#pragma mark -
#pragma mark NSTextFieldNotifictions

- (void)controlTextDidBeginEditing:(NSNotification *)n {
    [self.listView setFrame:[self listViewRectForBounds:[self bounds]]];
    [[[self window] contentView] addSubview:self.listView];
    [self.listView setHidden:NO];
}


- (void)controlTextDidEndEditing:(NSNotification *)n {
    [self.listView removeFromSuperview];
}


- (void)controlTextDidChange:(NSNotification *)n {
    [self.listView setHidden:![[textField stringValue] length]];
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
    
    item.selected = (i == listView.selectedItemIndex);
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
        self.textField = [[[TDFooBarTextField alloc] initWithFrame:r] autorelease];
        [textField setDelegate:self];
        [(TDFooBarTextField *)textField setBar:self];
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
        self.listView = [[[TDFooBarListView alloc] initWithFrame:r] autorelease];
        [listView setAutoresizingMask:0];
        listView.dataSource = self;
        listView.delegate = self;
    }
    return listView;
}


@synthesize dataSource;
@synthesize textField;
@synthesize listView;
@end
