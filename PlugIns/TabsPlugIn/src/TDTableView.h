//
//  FUTabsTableView.h
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TDTableRowView;
@protocol TDTableViewDataSource;
@protocol TDTableViewDelegate;

typedef enum {
    TDTableViewOrientationPortrait,
    TDTableViewOrientationLandscape
} TDTableViewOrientation;

@interface TDTableView : NSView {
    id <TDTableViewDataSource>dataSource;
    id <TDTableViewDelegate>delegate;
    NSColor *backgroundColor;
    TDTableViewOrientation orientation;
    CGFloat rowHeight;
    NSInteger selectedRowIndex;

    NSScrollView *scrollView;
    NSMutableArray *rowViews;
}

- (void)reloadData;

- (id)dequeueReusableRowViewWithIdentifier:(NSString *)s;

- (void)layoutRows;

@property (nonatomic, assign) id <TDTableViewDataSource>dataSource;
@property (nonatomic, assign) id <TDTableViewDelegate>delegate;
@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, assign) TDTableViewOrientation orientation;
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

