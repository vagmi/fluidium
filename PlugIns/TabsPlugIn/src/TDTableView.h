//
//  FUTabsTableView.h
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TDTableRowView;
@class TDTableRowViewQueue;
@protocol TDTableViewDataSource;
@protocol TDTableViewDelegate;

@interface TDTableView : NSView {
    NSScrollView *scrollView;
    id <TDTableViewDataSource>dataSource;
    id <TDTableViewDelegate>delegate;
    NSColor *backgroundColor;
    CGFloat rowHeight;
    NSInteger selectedRowIndex;

    NSMutableArray *visibleRowViews;
    TDTableRowViewQueue *rowViewQueue;
}

- (void)reloadData;

- (id)dequeueReusableRowViewWithIdentifier:(NSString *)s;

- (void)layoutRows;

@property (nonatomic, retain) IBOutlet NSScrollView *scrollView;
@property (nonatomic, assign) id <TDTableViewDataSource>dataSource;
@property (nonatomic, assign) id <TDTableViewDelegate>delegate;
@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) NSInteger selectedRowIndex;
@end

@protocol TDTableViewDataSource <NSObject>
@required
- (NSInteger)numberOfRowsInTableView:(TDTableView *)tv;
- (TDTableRowView *)tableView:(TDTableView *)tv viewForRowAtIndex:(NSInteger)i;
@end

@protocol TDTableViewDelegate <NSObject>
@optional
- (CGFloat)tableView:(TDTableView *)tv heightForRowAtIndex:(NSInteger)i;
- (void)tableView:(TDTableView *)tv willDisplayView:(TDTableRowView *)rv forRowAtIndex:(NSInteger)i;
- (NSInteger)tableView:(TDTableView *)tv willSelectRowAtIndex:(NSInteger)i;
- (void)tableView:(TDTableView *)tv didSelectRowAtIndex:(NSInteger)i;
@end

