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
    CGFloat itemExtent;
    CGFloat itemMargin;
    NSInteger selectedItemIndex;
    TDListViewOrientation orientation;
    BOOL displaysTruncatedItems;
    
    NSMutableArray *listItemViews;
    TDListItemViewQueue *queue;
}

- (void)reloadData;
- (id)dequeueReusableItemWithIdentifier:(NSString *)s;
- (NSInteger)indexForItemAtPoint:(NSPoint)p;

@property (nonatomic, assign) IBOutlet NSScrollView *scrollView;
@property (nonatomic, assign) id <TDListViewDataSource>dataSource;
@property (nonatomic, assign) id <TDListViewDelegate>delegate;
@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, assign) CGFloat itemExtent; // height if isPortrait. width if isLandscape
@property (nonatomic, assign) CGFloat itemMargin; // height if isPortrait. width if isLandscape
@property (nonatomic, assign) NSInteger selectedItemIndex;
@property (nonatomic, assign) TDListViewOrientation orientation;
@property (nonatomic, assign) BOOL displaysTruncatedItems;

// convenience
@property (nonatomic, readonly, getter=isPortrait) BOOL portrait;
@property (nonatomic, readonly, getter=isLandscape) BOOL landscape;
@end

@protocol TDListViewDataSource <NSObject>
@required
- (NSUInteger)numberOfItemsInListView:(TDListView *)tv;
- (TDListItemView *)listView:(TDListView *)lv viewForItemAtIndex:(NSUInteger)i;
@end

@protocol TDListViewDelegate <NSObject>
@optional
- (CGFloat)listView:(TDListView *)lv extentForItemAtIndex:(NSUInteger)i; // should return height if isPortrait. shoud return width if isLandscape
- (void)listView:(TDListView *)lv willDisplayView:(TDListItemView *)itemView forItemAtIndex:(NSUInteger)i;
- (NSUInteger)listView:(TDListView *)lv willSelectItemAtIndex:(NSUInteger)i;
- (void)listView:(TDListView *)lv didSelectItemAtIndex:(NSUInteger)i;
- (void)listView:(TDListView *)lv emptyAreaWasDoubleClicked:(NSEvent *)evt;
- (NSMenu *)listView:(TDListView *)lv contextMenuForItemAtIndex:(NSUInteger)i;
@end

