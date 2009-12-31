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

typedef enum {
    TDListViewOrientationPortrait = 0,
    TDListViewOrientationLandscape
} TDListViewOrientation;

@interface TDListView : NSView {
    NSScrollView *scrollView;
    id <TDListViewDataSource>dataSource;
    id <TDListViewDelegate>delegate;
    NSColor *backgroundColor;
    CGFloat itemHeight;
    NSInteger selectedItemIndex;
    TDListViewOrientation orientation;
    
    NSMutableArray *visibleItemViews;
    TDListItemViewQueue *itemViewQueue;
}

- (void)reloadData;

- (id)dequeueReusableItemViewWithIdentifier:(NSString *)s;

@property (nonatomic, retain) IBOutlet NSScrollView *scrollView;
@property (nonatomic, assign) id <TDListViewDataSource>dataSource;
@property (nonatomic, assign) id <TDListViewDelegate>delegate;
@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, assign) NSInteger selectedItemIndex;
@property (nonatomic, assign) TDListViewOrientation orientation;
@end

@protocol TDListViewDataSource <NSObject>
@required
- (NSInteger)numberOfItemsInListView:(TDListView *)tv;
- (TDListItemView *)listView:(TDListView *)lv viewForItemAtIndex:(NSInteger)i;
@end

@protocol TDListViewDelegate <NSObject>
@optional
- (CGFloat)listView:(TDListView *)lv heightForItemAtIndex:(NSInteger)i;
- (void)listView:(TDListView *)lv willDisplayView:(TDListItemView *)rv forRowAtIndex:(NSInteger)i;
- (NSInteger)listView:(TDListView *)lv willSelectRowAtIndex:(NSInteger)i;
- (void)listView:(TDListView *)lv didSelectRowAtIndex:(NSInteger)i;
@end

