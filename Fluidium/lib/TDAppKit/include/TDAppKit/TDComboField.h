//
//  TDFooBar.h
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDBar.h>
#import <TDAppKit/TDListView.h>

@class TDComboField;
@class TDComboFieldTextView;

@protocol TDComboFieldDataSource <NSObject>
@required
- (NSUInteger)numberOfItemsInComboField:(TDComboField *)cf;
- (id)comboField:(TDComboField *)cf objectAtIndex:(NSUInteger)i;
@optional
- (NSUInteger)comboField:(TDComboField *)cf indexOfItemWithStringValue:(NSString *)string;
- (NSString *)comboField:(TDComboField *)cf completedString:(NSString *)uncompletedString;
@end

@protocol TDComboFieldDelegate <NSObject>
@required
- (BOOL)comboField:(TDComboField *)cf writeDataToPasteboard:(NSPasteboard*)pboard;
@end

@interface TDComboField : NSTextField <TDListViewDataSource, TDListViewDelegate> {
    id <TDComboFieldDataSource>dataSource;
    TDListView *listView;
    NSWindow *listWindow;
    TDComboFieldTextView *fieldEditor;
    NSMutableArray *buttons;
    BOOL shouldDrag;
}

- (BOOL)isListVisible;
- (void)escape:(id)sender;

- (NSRect)listWindowRectForBounds:(NSRect)bounds;
- (NSRect)listViewRectForBounds:(NSRect)bounds;

@property (nonatomic, assign) id <TDComboFieldDataSource>dataSource;
@property (nonatomic, retain) TDListView *listView;
@property (nonatomic, retain) NSWindow *listWindow;
@property (nonatomic, retain) TDComboFieldTextView *fieldEditor;
@property (nonatomic, retain) NSImage *image;


// buttons
- (NSButton *)addButtonWithSize:(NSSize)size;
- (NSButton *)buttonWithTag:(int)tag;
- (void)removeButton:(NSButton *)b;
- (NSRect)buttonFrame;

@property (nonatomic, readonly, retain) NSArray *buttons;
@end
