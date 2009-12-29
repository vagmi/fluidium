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
    TDTableViewOrientation orientation;
    CGFloat rowHeight;

    NSScrollView *scrollView;
    NSMutableArray *rowViews;
}

- (void)reloadData;

- (void)layoutRowViews;

@property (nonatomic, assign) id <TDTableViewDataSource>dataSource;
@property (nonatomic, assign) id <TDTableViewDelegate>delegate;
@property (nonatomic, assign) TDTableViewOrientation orientation;
@property (nonatomic, assign) CGFloat rowHeight;
@end

@protocol TDTableViewDataSource <NSObject>
- (NSInteger)numberOfRowsInTableView:(TDTableView *)tv;
- (TDTableRowView *)tableView:(TDTableView *)tv viewForRowAtIndex:(NSInteger)i;
@end

@protocol TDTableViewDelegate <NSObject>
- (CGFloat)tableView:(TDTableView *)tv heightForRowAtIndex:(NSInteger)i;
- (void)tableView:(TDTableView *)tv willDisplayView:(TDTableRowView *)rv forRowAtIndex:(NSInteger)i;
- (NSInteger)tableView:(TDTableView *)tv willSelectRowAtIndex:(NSInteger)i;
- (NSInteger)tableView:(TDTableView *)tv didSelectRowAtIndex:(NSInteger)i;
@end

