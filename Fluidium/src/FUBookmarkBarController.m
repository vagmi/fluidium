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
#import "NSPasteboard+FUAdditions.h"
#import "WebURLsWithTitles.h"
//#import "WebIconDatabase.h"
//#import "WebIconDatabase+FUAdditions.h"
#import <TDAppKit/TDListItemView.h>
#import <TDAppKit/TDBar.h>

#define BUTTON_MAX_WIDTH 180
#define SEPARATOR_MIN_X 3
#define BUTTON_X_PADDING 7.5
#define BUTTON_X_MARGIN 2

#define BOOKMARK_BAR_HEIGHT 22

@interface FUBookmarkBarController ()
- (NSArray *)pasteboardTypes;

@property (nonatomic, retain) FUBookmark *draggingBookmark;
@end

@implementation FUBookmarkBarController

- (id)init {
    if (self = [super init]) {

    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.listView = nil;
    self.bar = nil;
    self.draggingBookmark = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bookmarksDidChange:) name:FUBookmarksDidChangeNotification object:nil];

    // setup drag and drop
    [listView registerForDraggedTypes:[self pasteboardTypes]];
    [listView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [listView setDraggingSourceOperationMask:NSDragOperationDelete forLocal:NO];
    
    // setup ui.
    listView.displaysClippedItems = NO;
    
    listView.itemMargin = 2;
    listView.orientation = TDListViewOrientationLandscape;
    [listView reloadData];
    
    // setup bar colors
    NSColor *bgColor = FUMainTabBackgroundColor();
    bar.mainBgGradient = [[[NSGradient alloc] initWithStartingColor:[bgColor colorWithAlphaComponent:.65] endingColor:bgColor] autorelease];
    bgColor = FUNonMainTabBackgroundColor();
    bar.nonMainBgGradient = [[[NSGradient alloc] initWithStartingColor:[bgColor colorWithAlphaComponent:.45] endingColor:bgColor] autorelease];
    bar.mainTopBorderColor = [NSColor colorWithDeviceWhite:.4 alpha:1];
    bar.nonMainTopBorderColor = [NSColor colorWithDeviceWhite:.64 alpha:1];
    bar.mainTopBevelColor = [NSColor colorWithDeviceWhite:.75 alpha:1];
    bar.nonMainTopBevelColor = [NSColor colorWithDeviceWhite:.9 alpha:1];
    bar.mainBottomBevelColor = nil;
    bar.nonMainBottomBevelColor = nil;
}


#pragma mark -
#pragma mark Notifications

- (void)bookmarksDidChange:(NSNotification *)n {
    [listView reloadData];
}


#pragma mark -
#pragma mark Private

- (NSArray *)pasteboardTypes {
    return [NSArray arrayWithObjects:WebURLsWithTitlesPboardType, NSURLPboardType, nil];
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
    [b setNextResponder:listView];

    [itemView setNeedsDisplay:YES];
    [b setNeedsDisplay:YES];
    
    return itemView;
}


#pragma mark -
#pragma mark TDListViewDelegate

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


#pragma mark -
#pragma mark TDListViewDelegate Drag and Drop

/*
 This method is called after it has been determined that a drag should begin, but before the drag has been started. 
 To refuse the drag, return NO. To start the drag, declare the pasteboard types that you support with -[NSPasteboard declareTypes:owner:], 
 place your data for the items at the given indexes on the pasteboard, and return YES from the method. 
 The drag image and other drag related information will be set up and provided by the view once this call returns YES. 
 You need to implement this method for your list view to be a drag source.
 */
- (BOOL)listView:(TDListView *)lv writeItemAtIndex:(NSUInteger)i toPasteboard:(NSPasteboard *)pboard {
    [pboard declareTypes:[self pasteboardTypes] owner:self];
    
    self.draggingBookmark = [[[FUBookmarkController instance] bookmarks] objectAtIndex:i];
    [draggingBookmark writeAllToPasteboard:pboard];
    
    [[FUBookmarkController instance] removeBookmark:draggingBookmark];          
    
    [listView reloadData];
    return YES;
}


- (NSDragOperation)listView:(TDListView *)lv validateDrop:(id <NSDraggingInfo>)dragInfo proposedIndex:(NSUInteger *)proposedDropIndex dropOperation:(TDListViewDropOperation *)proposedDropOperation {
    //NSLog(@"%s", _cmd);
    *proposedDropOperation = TDListViewDropBefore;
    if (draggingBookmark) {
        return NSDragOperationMove;
    } else {
        return NSDragOperationCopy;
    }
}


- (BOOL)listView:(TDListView *)lv acceptDrop:(id <NSDraggingInfo>)dragInfo index:(NSUInteger)i dropOperation:(TDListViewDropOperation)dropOperation {
    NSPasteboard *pboard = [dragInfo draggingPasteboard];
    
    if (![pboard hasTypeFromArray:[self pasteboardTypes]]) {
        return NO;
    }
    
    NSArray *bmarks = [FUBookmark bookmarksFromPasteboard:pboard];
    FUBookmark *bmark = [bmarks objectAtIndex:0];
    if (-1 == i) {
        [[FUBookmarkController instance] appendBookmark:bmark];
    } else {
        [[FUBookmarkController instance] insertBookmark:bmark atIndex:i];
    }
    [listView reloadData];
    
    if (!draggingBookmark) {
        [[[listView window] windowController] runEditTitleSheetForBookmark:bmark];
    }
    
    self.draggingBookmark = nil;
    return YES;
}

@synthesize listView;
@synthesize bar;
@synthesize draggingBookmark;
@end
