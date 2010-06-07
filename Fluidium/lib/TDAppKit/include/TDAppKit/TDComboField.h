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
@class TDFooBarTextView;

@protocol TDComboFieldDataSource <NSObject>
@required
- (NSUInteger)numberOfItemsInComboField:(TDComboField *)cf;
- (id)comboField:(TDComboField *)cf objectAtIndex:(NSUInteger)i;
@optional
- (NSUInteger)comboField:(TDComboField *)cf indexOfItemWithStringValue:(NSString *)string;
- (NSString *)comboField:(TDComboField *)cf completedString:(NSString *)uncompletedString;
@end

@interface TDComboField : NSTextField <TDListViewDataSource, TDListViewDelegate> {
    id <TDComboFieldDataSource>dataSource;
    TDListView *listView;
    NSWindow *listWindow;
    TDFooBarTextView *fieldEditor;
}

- (BOOL)isListVisible;

- (NSRect)listWindowRectForBounds:(NSRect)bounds;
- (NSRect)listViewRectForBounds:(NSRect)bounds;

@property (nonatomic, assign) id <TDComboFieldDataSource>dataSource;
@property (nonatomic, retain) TDListView *listView;
@property (nonatomic, retain) NSWindow *listWindow;
@property (nonatomic, retain) TDFooBarTextView *fieldEditor;
@end
