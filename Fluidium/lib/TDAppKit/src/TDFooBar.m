//
//  TDFooBar.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDFooBar.h>
#import <TDAppKit/TDListItem.h>
#import "TDFooBarListView.h"
#import "TDFooBarListItem.h"
#import "TDFooBarTextView.h"

#define TEXT_MARGIN_X 20.0
#define TEXT_MARGIN_Y 5.0
#define LIST_MARGIN_Y 5.0

@interface TDFooBar ()
- (void)removeListWindow;
- (void)resizeListWindow;
- (void)textWasInserted:(id)insertString;
- (void)removeTextFieldSelection;
- (void)addTextFieldSelectionFromListSelection;
@end

@implementation TDFooBar

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidResignActive:) name:NSApplicationDidResignActiveNotification object:NSApp];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeListWindow];

    self.dataSource = nil;
    self.textField = nil;
    self.listView = nil;
    self.listWindow = nil;
    self.fieldEditor = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [[self window] setDelegate:self];
    [self resizeSubviewsWithOldSize:NSZeroSize];
}


- (BOOL)isListVisible {
    return nil != [self.listWindow parentWindow];
}


#pragma mark -
#pragma mark Bounds

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    [self resizeSubviewsWithOldSize:NSZeroSize];
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSRect bounds = [self bounds];
    
    [self.textField setFrame:[self textFieldRectForBounds:bounds]];
    [self removeListWindow];
}


- (void)addListWindow {
    if (![self isListVisible]) {
        [[self window] addChildWindow:self.listWindow ordered:NSWindowAbove];
    }
}


- (void)removeListWindow {
    if ([self isListVisible]) {
        [[self window] removeChildWindow:self.listWindow];
        [self.listWindow orderOut:nil];
    }
}


- (void)resizeListWindow {
    BOOL hidden = ![[textField stringValue] length];
    
    if (hidden) {
        [self removeListWindow];
    } else {
        [self addListWindow];
    }

    if (!hidden) {
        NSRect bounds = [self bounds];
        [self.listView setFrame:[self listViewRectForBounds:bounds]];
        [self.listWindow setFrame:[self listWindowRectForBounds:bounds] display:YES];
        [self.listView reloadData];
    }
}


- (NSRect)textFieldRectForBounds:(NSRect)bounds {
    return NSMakeRect(TEXT_MARGIN_X, TEXT_MARGIN_Y, bounds.size.width - (TEXT_MARGIN_X * 2), 22);
}


- (NSRect)listWindowRectForBounds:(NSRect)bounds {
    NSRect windowFrame = [[self window] frame];
    NSRect textFrame = [self.textField frame];
    NSRect barFrame = [self frame];
    NSRect listRect = [self listViewRectForBounds:bounds];

    CGFloat x = windowFrame.origin.x + textFrame.origin.x;
    CGFloat y = windowFrame.origin.y + barFrame.origin.y + textFrame.origin.y - listRect.size.height - LIST_MARGIN_Y;
    
    return NSMakeRect(x, y, listRect.size.width, listRect.size.height);
}


- (NSRect)listViewRectForBounds:(NSRect)bounds {
    CGFloat listHeight = [TDFooBarListItem defaultHeight] * [self numberOfItemsInListView:listView];
    return NSMakeRect(0, 0, bounds.size.width - (TEXT_MARGIN_X * 2), listHeight);
}


#pragma mark -
#pragma mark NSResponder

- (void)moveUp:(id)sender {
    [self removeTextFieldSelection];

    NSUInteger i = listView.selectedItemIndex;
    if (i <= 0 || NSNotFound == i) {
        i = 0;
    } else {
        i--;
    }
    listView.selectedItemIndex = i;
    [listView reloadData];
    
    [self addTextFieldSelectionFromListSelection];
}


- (void)moveDown:(id)sender {
    [self removeTextFieldSelection];
    
    NSUInteger i = listView.selectedItemIndex;
    NSUInteger last = [self numberOfItemsInListView:listView] - 1;
    if (i < last) {
        i++;
    } else if (NSNotFound == i) {
        i = 0;
    }
    listView.selectedItemIndex = i;
    [listView reloadData];

    [self addTextFieldSelectionFromListSelection];
}


#pragma mark -
#pragma mark NSWindowDelegate

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
    [self removeListWindow];
    return frameSize;
}


- (id)windowWillReturnFieldEditor:(NSWindow *)win toObject:(id)obj {
    if (obj == textField) {
        if (!fieldEditor) {
            self.fieldEditor = [[[TDFooBarTextView alloc] initWithFrame:NSZeroRect] autorelease];
            fieldEditor.bar = self;
        }
        return fieldEditor; 
    } else {
        return nil;
    }
}


#pragma mark -
#pragma mark NSApplicationNotifications

- (void)applicationDidResignActive:(NSNotification *)n {
    [self removeListWindow];
}


#pragma mark -
#pragma mark NSTextFieldDelegate

// <esc> was pressed
- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    if ([self isListVisible]) {
        [self removeListWindow];

        // clear auto-completed text
        NSRange r = [[textField currentEditor] selectedRange];
        NSString *s = [[textField stringValue] substringToIndex:r.location];
        [textField setStringValue:s];
    } else {
        [self addListWindow];
        [self addTextFieldSelectionFromListSelection];
    }
    return nil;
}


#pragma mark -
#pragma mark NSTextFieldNotifictions

- (void)controlTextDidBeginEditing:(NSNotification *)n {
    NSParameterAssert([n object] == textField);

    self.listView.selectedItemIndex = 0;
    [self resizeListWindow];
}


- (void)controlTextDidEndEditing:(NSNotification *)n {
    NSParameterAssert([n object] == textField);

    [self removeListWindow];
}


- (void)controlTextDidChange:(NSNotification *)n {
    NSParameterAssert([n object] == textField);
    
    self.listView.selectedItemIndex = 0;
    [self.listView reloadData];
    [self resizeListWindow];
}


#pragma mark -
#pragma mark Private

- (void)textWasInserted:(id)insertString; {
    if (dataSource && [dataSource respondsToSelector:@selector(fooBar:completedString:)]) {
        NSString *s = [textField stringValue];
        NSUInteger loc = [s length];
        s = [dataSource fooBar:self completedString:s];
        
        NSRange range = NSMakeRange(loc, [s length] - loc);
        [textField setStringValue:s];
        [[textField currentEditor] setSelectedRange:range];
    }
}


- (void)removeTextFieldSelection {
    NSRange range = [[textField currentEditor] selectedRange];
    NSString *s = [[textField stringValue] substringToIndex:range.location];
    [textField setStringValue:s];
}


- (void)addTextFieldSelectionFromListSelection {
    NSString *s = [dataSource fooBar:self objectAtIndex:listView.selectedItemIndex];
    
    NSUInteger loc = [[textField stringValue] length];
    NSRange range = NSMakeRange(loc, [s length] - loc);
    [textField setStringValue:s];
    [[textField currentEditor] setSelectedRange:range];
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
    
    item.first = (0 == i);
    item.last = (i == [self numberOfItemsInListView:lv] - 1);
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

- (TDListView *)listView {
    if (!listView) {
        NSRect r = [self listViewRectForBounds:[self bounds]];
        self.listView = [[[TDFooBarListView alloc] initWithFrame:r] autorelease];
        [listView setAutoresizingMask:NSViewWidthSizable];
        listView.dataSource = self;
        listView.delegate = self;
    }
    return listView;
}


- (NSWindow *)listWindow {
    if (!listWindow) {
        NSRect r = [self listWindowRectForBounds:[self bounds]];
        self.listWindow = [[[NSWindow alloc] initWithContentRect:r styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES] autorelease];
        [listWindow setOpaque:NO];
        [listWindow setHasShadow:YES];
        [listWindow setBackgroundColor:[NSColor clearColor]];
        [[listWindow contentView] addSubview:self.listView];
    }
    return listWindow;
}

@synthesize dataSource;
@synthesize textField;
@synthesize listView;
@synthesize listWindow;
@synthesize fieldEditor;
@end
