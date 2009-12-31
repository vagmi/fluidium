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

@class TDListItemView;
@class TDListItemViewQueue;
@protocol TDListViewDataSource;
@protocol TDListViewDelegate;

@interface TDListView : NSView {
    NSScrollView *scrollView;
    id <TDListViewDataSource>dataSource;
    id <TDListViewDelegate>delegate;
    NSColor *backgroundColor;
    CGFloat rowHeight;
    NSInteger selectedRowIndex;

    NSMutableArray *visibleRowViews;
    TDListItemViewQueue *rowViewQueue;
}

- (void)reloadData;

- (id)dequeueReusableRowViewWithIdentifier:(NSString *)s;

- (void)layoutRows;

@property (nonatomic, retain) IBOutlet NSScrollView *scrollView;
@property (nonatomic, assign) id <TDListViewDataSource>dataSource;
@property (nonatomic, assign) id <TDListViewDelegate>delegate;
@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) NSInteger selectedRowIndex;
@end

@protocol TDListViewDataSource <NSObject>
@required
- (NSInteger)numberOfRowsInTableView:(TDListView *)tv;
- (TDListItemView *)tableView:(TDListView *)tv viewForRowAtIndex:(NSInteger)i;
@end

@protocol TDListViewDelegate <NSObject>
@optional
- (CGFloat)tableView:(TDListView *)tv heightForRowAtIndex:(NSInteger)i;
- (void)tableView:(TDListView *)tv willDisplayView:(TDListItemView *)rv forRowAtIndex:(NSInteger)i;
- (NSInteger)tableView:(TDListView *)tv willSelectRowAtIndex:(NSInteger)i;
- (void)tableView:(TDListView *)tv didSelectRowAtIndex:(NSInteger)i;
@end

