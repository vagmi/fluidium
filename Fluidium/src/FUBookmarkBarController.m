//  Copyright 2010 Todd Ditchendorf
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

#import "FUBookmarkBarController.h"
#import "FUBookmarkController.h"
#import "FUBookmarkWindowController.h"
#import "FUBookmarkBarListItemView.h"
#import "FUBookmark.h"
#import "FUWindowController.h"
#import "FUUtils.h"
#import "FUNotifications.h"
#import <TDAppKit/TDListItemView.h>

#define BUTTON_MAX_WIDTH 180
#define SEPARATOR_MIN_X 3
#define BUTTON_X_PADDING 7.5
#define BUTTON_X_MARGIN 2

#define BOOKMARK_BAR_HEIGHT 22

@implementation FUBookmarkBarController

- (id)init {
    if (self = [super init]) {

    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.listView = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bookmarksDidChange:) name:FUBookmarksDidChangeNotification object:nil];

    listView.itemMargin = 2;
    listView.orientation = TDListViewOrientationLandscape;
    [listView reloadData];
}


#pragma mark -
#pragma mark Notifications

- (void)bookmarksDidChange:(NSNotification *)n {
    [listView reloadData];
}


#pragma mark -
#pragma mark TDListViewDataSource

- (NSUInteger)numberOfItemsInListView:(TDListView *)tv {
    return [[[FUBookmarkController instance] bookmarks] count];
}


- (TDListItemView *)listView:(TDListView *)lv viewForItemAtIndex:(NSUInteger)i {
    FUBookmarkBarListItemView *itemView = [listView dequeueReusableItemWithIdentifier:[FUBookmarkBarListItemView reuseIdentifier]];

    if (!itemView) {
        itemView = [[[FUBookmarkBarListItemView alloc] init] autorelease];
    }
    
    FUBookmark *bmark = [[[FUBookmarkController instance] bookmarks] objectAtIndex:i];
    FUBookmarkBarButton *b = itemView.button;
    
    [b setTitle:bmark.title];
    [b setTarget:[[listView window] windowController]];
    [b setAction:@selector(bookmarkClicked:)];
    [b setTag:i];

    [itemView setNeedsDisplay:YES];
    [b setNeedsDisplay:YES];
    
    return itemView;
}


#pragma mark -
#pragma mark TDListViewDataSource

- (CGFloat)listView:(TDListView *)lv extentForItemAtIndex:(NSUInteger)i {
    FUBookmark *bmark = [[[FUBookmarkController instance] bookmarks] objectAtIndex:i];
    NSUInteger opts = NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine;
    
    NSDictionary *attrs = nil;
    if ([[listView window] isMainWindow]) {
        attrs = FUMainTabTextAttributes();
    } else {
        attrs = FUNonMainTabTextAttributes();
    }
    
    NSRect r = [bmark.title boundingRectWithSize:NSMakeSize(MAXFLOAT, BOOKMARK_BAR_HEIGHT) options:opts attributes:attrs];
    CGFloat w = r.size.width + BUTTON_X_PADDING*2;
    w = w > BUTTON_MAX_WIDTH ? BUTTON_MAX_WIDTH : w;
    return w;
}


- (void)listView:(TDListView *)lv willDisplayView:(TDListItemView *)itemView forItemAtIndex:(NSUInteger)i {
    
}


- (NSUInteger)listView:(TDListView *)lv willSelectItemAtIndex:(NSUInteger)i {
    return -1;
}


- (void)listView:(TDListView *)lv emptyAreaWasDoubleClicked:(NSEvent *)evt {
    [[FUBookmarkWindowController instance] showWindow:self];
}


- (NSMenu *)listView:(TDListView *)lv contextMenuForItemAtIndex:(NSUInteger)i {
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    
    return menu;
}

@synthesize listView;
@end
