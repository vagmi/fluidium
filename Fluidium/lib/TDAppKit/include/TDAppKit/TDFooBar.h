//
//  TDFooBar.h
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDBar.h>
#import <TDAppKit/TDListView.h>

@class TDFooBar;
@class TDFooBarTextView;

@protocol TDFooBarDataSource <NSObject>
@required
- (NSUInteger)numberOfItemsInFooBar:(TDFooBar *)fb;
- (id)fooBar:(TDFooBar *)fb objectAtIndex:(NSUInteger)i;
@optional
- (NSUInteger)fooBar:(TDFooBar *)fb indexOfItemWithStringValue:(NSString *)string;
- (NSString *)fooBar:(TDFooBar *)fb completedString:(NSString *)uncompletedString;
@end

@interface TDFooBar : TDBar <TDListViewDataSource, TDListViewDelegate> {
    id <TDFooBarDataSource>dataSource;
    NSTextField *textField;
    TDListView *listView;
    NSWindow *listWindow;
    TDFooBarTextView *fieldEditor;
}

- (BOOL)isListVisible;

- (NSRect)textFieldRectForBounds:(NSRect)bounds;
- (NSRect)listWindowRectForBounds:(NSRect)bounds;
- (NSRect)listViewRectForBounds:(NSRect)bounds;

@property (nonatomic, assign) id <TDFooBarDataSource>dataSource;
@property (nonatomic, retain) IBOutlet NSTextField *textField;
@property (nonatomic, retain) TDListView *listView;
@property (nonatomic, retain) NSWindow *listWindow;
@property (nonatomic, retain) TDFooBarTextView *fieldEditor;
@end
