//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

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

