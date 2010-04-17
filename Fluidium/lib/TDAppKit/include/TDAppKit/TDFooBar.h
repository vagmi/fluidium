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
@class TDFooBarListShadowView;

@protocol TDFooBarDataSource
- (NSUInteger)numberOfItemsInFooBar:(TDFooBar *)fb;
- (id)fooBar:(TDFooBar *)fb objectAtIndex:(NSUInteger)i;
@end

@interface TDFooBar : TDBar <TDListViewDataSource, TDListViewDelegate> {
    id <TDFooBarDataSource>dataSource;
    NSTextField *textField;
    TDListView *listView;
    TDFooBarListShadowView *shadowView;
    TDFooBarTextView *fieldEditor;
}

- (NSRect)textFieldRectForBounds:(NSRect)bounds;
- (NSRect)listShadowViewRectForBounds:(NSRect)bounds;
- (NSRect)listViewRectForBounds:(NSRect)bounds;

@property (nonatomic, assign) id <TDFooBarDataSource>dataSource;
@property (nonatomic, retain) IBOutlet NSTextField *textField;
@property (nonatomic, retain) TDListView *listView;
@property (nonatomic, retain) TDFooBarListShadowView *shadowView;
@property (nonatomic, retain) TDFooBarTextView *fieldEditor;
@end
