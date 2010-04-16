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

@protocol TDFooBarDataSource
- (NSUInteger)numberOfItemsInFooBar:(TDFooBar *)fb;
- (id)fooBar:(TDFooBar *)fb objectAtIndex:(NSUInteger)i;
@end

@interface TDFooBar : TDBar <TDListViewDataSource, TDListViewDelegate> {
    id <TDFooBarDataSource>dataSource;
    NSTextField *textField;
    TDListView *listView;
    TDFooBarTextView *fieldEditor;
}

- (NSRect)textFieldRectForBounds:(NSRect)bounds;
- (NSRect)listViewRectForBounds:(NSRect)bounds;

@property (nonatomic, assign) id <TDFooBarDataSource>dataSource;
@property (nonatomic, retain) NSTextField *textField;
@property (nonatomic, retain) TDListView *listView;
@property (nonatomic, retain) TDFooBarTextView *fieldEditor;
@end
