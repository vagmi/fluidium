//
//  TDFooBar.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDComboField.h>
#import <TDAppKit/TDListItem.h>
#import "TDFooBarListView.h"
#import "TDFooBarListItem.h"
#import "TDComboFieldTextView.h"

#define LIST_MARGIN_Y 5.0

@interface TDComboField ()
- (void)removeListWindow;
- (void)resizeListWindow;
- (void)textWasInserted:(id)insertString;
- (void)removeTextFieldSelection;
- (void)addTextFieldSelectionFromListSelection;
@end

@implementation TDComboField

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {

    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeListWindow];

    self.dataSource = nil;
    self.listView = nil;
    self.listWindow = nil;
    self.fieldEditor = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidResignActive:) name:NSApplicationDidResignActiveNotification object:NSApp];

    [self setDelegate:self];

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
    [self removeListWindow];
    [super resizeSubviewsWithOldSize:oldSize];
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
    BOOL hidden = ![[self stringValue] length];
    
    if (hidden) {
        [self removeListWindow];
    } else {
        NSRect bounds = [self bounds];
        [self.listView setFrame:[self listViewRectForBounds:bounds]];
        [self.listWindow setFrame:[self listWindowRectForBounds:bounds] display:YES];
        [self.listView reloadData];

        [self addListWindow];
    }
}


- (NSRect)listWindowRectForBounds:(NSRect)bounds {
    NSRect windowFrame = [[self window] frame];
    NSRect textFrame = [self frame];
    NSRect listRect = [self listViewRectForBounds:bounds];

    CGFloat x = windowFrame.origin.x + textFrame.origin.x;
    CGFloat y = windowFrame.origin.y + textFrame.origin.y - listRect.size.height - LIST_MARGIN_Y;
    
    return NSMakeRect(x, y, listRect.size.width, listRect.size.height);
}


- (NSRect)listViewRectForBounds:(NSRect)bounds {
    CGFloat listHeight = [TDFooBarListItem defaultHeight] * [self numberOfItemsInListView:listView];
    return NSMakeRect(0, 0, bounds.size.width, listHeight);
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
    if (obj == self) {
        if (!fieldEditor) {
            self.fieldEditor = [[[TDComboFieldTextView alloc] initWithFrame:NSZeroRect] autorelease];
            fieldEditor.comboField = self;
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
        NSRange r = [[self currentEditor] selectedRange];
        NSString *s = [[self stringValue] substringToIndex:r.location];
        [self setStringValue:s];
    } else {
        [self addListWindow];
        [self addTextFieldSelectionFromListSelection];
    }
    return nil;
}


#pragma mark -
#pragma mark NSTextFieldNotifictions

- (void)controlTextDidBeginEditing:(NSNotification *)n {
    NSParameterAssert([n object] == self);

    self.listView.selectedItemIndex = 0;
    [self resizeListWindow];
}


- (void)controlTextDidEndEditing:(NSNotification *)n {
    NSParameterAssert([n object] == self);

    [self removeListWindow];
}


- (void)controlTextDidChange:(NSNotification *)n {
    NSParameterAssert([n object] == self);
    
    self.listView.selectedItemIndex = 0;
    [self.listView reloadData];
    [self resizeListWindow];
}


#pragma mark -
#pragma mark Private

- (void)textWasInserted:(id)insertString; {
    if (dataSource && [dataSource respondsToSelector:@selector(comboField:completedString:)]) {
        NSString *s = [self stringValue];
        NSUInteger loc = [s length];
        s = [dataSource comboField:self completedString:s];
        
        NSRange range = NSMakeRange(loc, [s length] - loc);
        [self setStringValue:s];
        [[self currentEditor] setSelectedRange:range];
    }
}


- (void)removeTextFieldSelection {
    NSRange range = [[self currentEditor] selectedRange];
    NSString *s = [[self stringValue] substringToIndex:range.location];
    [self setStringValue:s];
}


- (void)addTextFieldSelectionFromListSelection {
    NSString *s = [dataSource comboField:self objectAtIndex:listView.selectedItemIndex];
    
    NSUInteger loc = [[self stringValue] length];
    NSRange range = NSMakeRange(loc, [s length] - loc);
    [self setStringValue:s];
    [[self currentEditor] setSelectedRange:range];
}

                            
#pragma mark -
#pragma mark TDListViewDataSource

- (NSUInteger)numberOfItemsInListView:(TDListView *)lv {
    //NSAssert(dataSource, @"must provide a FooBarDataSource");
    return [dataSource numberOfItemsInComboField:self];
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
    item.labelText = [dataSource comboField:self objectAtIndex:i];
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
//@synthesize textField;
@synthesize listView;
@synthesize listWindow;
@synthesize fieldEditor;
@end
