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

#import "FUTabsViewController.h"
#import "FUNotifications.h"
#import "FUPlugIn.h"
#import "FUPlugInAPI.h"
#import "FUTabsPlugIn.h"
#import "FUTabModel.h"
#import "FUTabListItemView.h"
#import "WebURLsWithTitles.h"
#import <WebKit/WebKit.h>

#define KEY_SELECTION_INDEXES @"selectionIndexes"
#define KEY_TAB_CONTROLLER @"FUTabController"
#define KEY_INDEX @"FUIndex"

#define ASPECT_RATIO .7

#define TDTabPboardType @"TDTabPboardType"

@interface NSObject ()
// FUWindowController
- (NSTabView *)tabView;
- (void)openTab:(id)sender;
- (NSInteger)selectedTabIndex;
- (void)setSelectedTabIndex:(NSInteger)i;
- (NSArray *)tabControllers;
- (id)tabControllerAtIndex:(NSInteger)i;
- (BOOL)removeTabController:(id)tc;
- (void)addTabController:(id)tc atIndex:(NSInteger)i;
- (id)loadRequest:(NSURLRequest *)req inNewTab:(BOOL)shouldCreate atIndex:(NSInteger)i andSelect:(BOOL)select;
@end

@interface WebView ()
- (NSImage *)documentViewImageWithCurrentAspectRatio;
- (NSImage *)documentViewImageWithAspectRatio:(NSSize)size;
@end

@interface FUTabsViewController ()
- (NSArray *)webViews;
- (id)windowController;
- (void)updateAllTabModels;
- (void)updateAllTabModelsFromIndex:(NSInteger)startIndex;
- (void)updateSelectedTabModel;
- (void)updateTabModelLaterAtIndex:(NSNumber *)indexObj;
- (void)updateTabModelAtIndex:(NSInteger)i;
- (void)updateTabModel:(FUTabModel *)model fromWebView:(WebView *)wv atIndex:(NSInteger)i;
- (void)startObserveringTabController:(id)tc;
- (void)stopObserveringTabController:(id)tc;
- (BOOL)isVertical;
- (BOOL)isHorizontal;
@end

@implementation FUTabsViewController

- (id)init {
    return [self initWithNibName:@"FUTabsView" bundle:[NSBundle bundleForClass:[self class]]];
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    if (self = [super initWithNibName:name bundle:b]) {
        
    }
    return self;
}


- (void)dealloc {
    self.view = nil;
    self.listView = nil;
    self.scrollView = nil;
    self.plugIn = nil;
    self.plugInAPI = nil;
    self.tabModels = nil;
    self.drawer = nil;
    self.draggingTabController = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    // setup drag and drop
    [listView registerForDraggedTypes:[NSArray arrayWithObjects:TDTabPboardType, WebURLsWithTitlesPboardType, NSURLPboardType, nil]];
    [listView setDraggingSourceOperationMask:NSDragOperationMove|NSDragOperationDelete forLocal:YES];
    [listView setDraggingSourceOperationMask:NSDragOperationLink|NSDragOperationCopy forLocal:NO];

    // setup ui
    listView.displaysClippedItems = YES;
}


- (IBAction)closeTabButtonClick:(id)sender {
    id wc = [self windowController];
    id tc = [wc tabControllerAtIndex:[sender tag]];
    [wc removeTabController:tc];
}


#pragma mark -
#pragma mark Public

- (void)viewWillAppear {
    NSUInteger mask = [plugInAPI viewPlacementForPlugInIdentifier:[plugIn identifier]];
    
    if (FUPlugInViewPlacementIsDrawer(mask)) {
        listView.backgroundColor = [NSColor colorWithDeviceWhite:.95 alpha:1.0];
        listView.orientation = TDListViewOrientationPortrait;
    } else {
        listView.backgroundColor = [NSColor colorWithDeviceWhite:.9 alpha:1.0];
        if (FUPlugInViewPlacementIsVerticalSplitView(mask)) {
            listView.orientation = TDListViewOrientationPortrait;
        } else {
            listView.orientation = TDListViewOrientationLandscape;
        }
    }
}


- (void)viewDidAppear {
    [self updateAllTabModels];
}


- (void)viewWillDisappear {
    self.tabModels = nil;
}


#pragma mark -
#pragma mark TDListViewDataSource

- (NSUInteger)numberOfItemsInListView:(TDListView *)tv {
    return [tabModels count];
}


- (TDListItemView *)listView:(TDListView *)lv viewForItemAtIndex:(NSUInteger)i {
    FUTabListItemView *itemView = [lv dequeueReusableItemWithIdentifier:[FUTabListItemView reuseIdentifier]];
    
    if (!itemView) {
        itemView = [[[FUTabListItemView alloc] init] autorelease];
    }
    
    itemView.viewController = self;
    itemView.model = [tabModels objectAtIndex:i];
    
    return itemView;
}


#pragma mark -
#pragma mark TDListViewDelegate

- (CGFloat)listView:(TDListView *)lv extentForItemAtIndex:(NSUInteger)i {
    NSSize scrollSize = [scrollView frame].size;
    
    if (listView.isPortrait) {
        return floor(scrollSize.width * ASPECT_RATIO);
    } else {
        return floor(scrollSize.height * 1 / ASPECT_RATIO);
    }
}


- (void)listView:(TDListView *)lv willDisplayView:(TDListItemView *)itemView forItemAtIndex:(NSUInteger)i {
    
}


- (void)listView:(TDListView *)lv didSelectItemAtIndex:(NSUInteger)i {
    id wc = [self windowController];
    [wc setSelectedTabIndex:i];
}


- (void)listView:(TDListView *)lv emptyAreaWasDoubleClicked:(NSEvent *)evt {
    [[[self.view window] windowController] openTab:self];
}


#pragma mark -
#pragma mark TDListViewDelegate Drag

- (BOOL)listView:(TDListView *)lv writeItemAtIndex:(NSUInteger)i toPasteboard:(NSPasteboard *)pboard {
    id wc = [self windowController];
    self.draggingTabController = [wc tabControllerAtIndex:i];
    NSURL *URL = [NSURL URLWithString:[draggingTabController URLString]];

    if (URL && [wc removeTabController:draggingTabController]) {
        [pboard declareTypes:[NSArray arrayWithObjects:TDTabPboardType, nil] owner:self];
        return YES;
    }
    
    return NO;
}


#pragma mark -
#pragma mark TDListViewDelegate Drop

- (NSDragOperation)listView:(TDListView *)lv validateDrop:(id <NSDraggingInfo>)draggingInfo proposedIndex:(NSUInteger *)proposedDropIndex dropOperation:(TDListViewDropOperation *)proposedDropOperation {
    NSPasteboard *pboard = [draggingInfo draggingPasteboard];

    NSArray *types = [pboard types];
    
    if ([types containsObject:TDTabPboardType]) {
        return NSDragOperationMove|NSDragOperationDelete;
    } else if ([types containsObject:NSURLPboardType] || [types containsObject:WebURLsWithTitlesPboardType]) {
        return NSDragOperationLink|NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}


- (BOOL)listView:(TDListView *)lv acceptDrop:(id <NSDraggingInfo>)draggingInfo index:(NSUInteger)i dropOperation:(TDListViewDropOperation)dropOperation {
    NSPasteboard *pboard = [draggingInfo draggingPasteboard];
    
    id wc = [self windowController];
    NSArray *types = [pboard types];
    NSURL *URL = nil;
    if ([types containsObject:TDTabPboardType]) {
        [wc addTabController:draggingTabController atIndex:i];
        self.draggingTabController = nil;

        [self updateAllTabModelsFromIndex:i];
        return YES;

    } else {
        if ([types containsObject:NSURLPboardType]) {
            URL = [NSURL URLFromPasteboard:pboard];
        } else if ([types containsObject:WebURLsWithTitlesPboardType]) {
            NSArray *URLs = [WebURLsWithTitles URLsFromPasteboard:pboard];
            if ([URLs count]) {
                URL = [URLs objectAtIndex:0];
            }
        }
        
        if (URL) {
            [[self windowController] loadRequest:[NSURLRequest requestWithURL:URL] inNewTab:YES atIndex:i andSelect:YES];
            return YES;
        }
    }
    
    return NO;
}


#pragma mark -
#pragma mark FUWindowControllerNotifcations

- (void)windowControllerDidOpenTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:KEY_INDEX] integerValue];
    [self updateAllTabModelsFromIndex:i];
    
    id tc = [[n userInfo] objectForKey:KEY_TAB_CONTROLLER];
    [self startObserveringTabController:tc];
}


- (void)windowControllerWillCloseTab:(NSNotification *)n {
    id tc = [[n userInfo] objectForKey:KEY_TAB_CONTROLLER];
    [self stopObserveringTabController:tc];
}


- (void)windowControllerDidCloseTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:KEY_INDEX] integerValue];
    [self updateAllTabModelsFromIndex:i];
}


- (void)windowControllerDidChangeSelectedTab:(NSNotification *)n {
    [self updateSelectedTabModel];
}


- (void)windowControllerDidChangeTabOrder:(NSNotification *)n {
    NSUInteger index = [[[n userInfo] objectForKey:@"FUIndex"] unsignedIntegerValue];
    NSUInteger priorIndex = [[[n userInfo] objectForKey:@"FUPriorIndex"] unsignedIntegerValue];
    
    NSUInteger i = index < priorIndex ? index : priorIndex;
    [self updateAllTabModelsFromIndex:i];
}


#pragma mark -
#pragma mark FUTabControllerNotifcations

- (void)tabControllerProgressDidChange:(NSNotification *)n {
    if (0 == ++changeCount % 3) { // only update web image every third notification
        NSInteger i = [[[n userInfo] objectForKey:KEY_INDEX] integerValue];
        [self updateTabModelAtIndex:i];
    }
}


- (void)tabControllerDidFinishLoad:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:KEY_INDEX] integerValue];
    [self updateTabModelAtIndex:i];
    
    [self performSelector:@selector(updateTabModelLaterAtIndex:) withObject:[NSNumber numberWithInteger:i] afterDelay:.6];
}


#pragma mark -
#pragma mark NSDrawerNotifications

- (void)drawerWillOpen:(NSNotification *)n {
    self.drawer = [n object];
}

    
- (void)drawerWillClose:(NSNotification *)n {
    self.drawer = nil;
}


#pragma mark -
#pragma mark Private

- (NSArray *)webViews {
    if (drawer) {
        return [plugInAPI webViewsForDrawer:drawer];
    } else {
        return [plugInAPI webViewsForWindow:[self.view window]];
    }
}


- (id)windowController {
    if (drawer) {
        return [[drawer parentWindow] windowController];
    } else {
        return [[self.view window] windowController];
    }
}


- (void)updateAllTabModels {
    [self updateAllTabModelsFromIndex:0];
}
    

- (void)updateAllTabModelsFromIndex:(NSInteger)startIndex {

    NSArray *wvs = [self webViews];
    NSInteger webViewsCount = [wvs count];
    
    NSMutableArray *newModels = nil;
    if (startIndex && tabModels) {
        newModels = [[[tabModels subarrayWithRange:NSMakeRange(0, startIndex)] mutableCopy] autorelease];
    } else {
        newModels = [NSMutableArray arrayWithCapacity:webViewsCount];
    }

    NSInteger newModelsCount = [newModels count];
    NSInteger i = startIndex;
    for ( ; i < webViewsCount; i++) {
        WebView *wv = [wvs objectAtIndex:i];
        FUTabModel *model = [[[FUTabModel alloc] init] autorelease];
        [self updateTabModel:model fromWebView:wv atIndex:i];
        if (i < newModelsCount) {
            [newModels replaceObjectAtIndex:i withObject:model];
        } else {
            [newModels addObject:model];
        }
    }
    
    self.tabModels = newModels;
    
    id wc = [self windowController];
    for (id tc in [wc tabControllers]) {
        [self startObserveringTabController:tc];
    }
    
    [self updateSelectedTabModel];
    
    [listView reloadData];
}


- (void)updateSelectedTabModel {
    NSInteger selectedIndex = [[self windowController] selectedTabIndex];

    if (selectedModel) {
        selectedModel.selected = NO;
    }
    
    if (selectedIndex >= 0 && selectedIndex < [tabModels count]) {
        selectedModel = [tabModels objectAtIndex:selectedIndex];
        selectedModel.selected = YES;
        
        [listView setSelectedItemIndex:selectedIndex];
    }
}


- (void)updateTabModelLaterAtIndex:(NSNumber *)indexObj {
    [self updateTabModelAtIndex:[indexObj integerValue]];
}


- (void)updateTabModelAtIndex:(NSInteger)i {
    NSArray *wvs = [self webViews];
                    
    if (i < [wvs count]) {
        WebView *wv = [wvs objectAtIndex:i];
        
        FUTabModel *model = [tabModels objectAtIndex:i];
        [self updateTabModel:model fromWebView:wv atIndex:i];
    }
}


- (void)updateTabModel:(FUTabModel *)model fromWebView:(WebView *)wv atIndex:(NSInteger)i {
    model.loading = [wv isLoading];
    model.index = i;

    NSString *title = [wv mainFrameTitle];
    if (![title length]) {
        if ([wv isLoading]) {
            title = NSLocalizedString(@"Loading...", @"");
        } else {
            title = NSLocalizedString(@"Untitled", @"");
        }
    }
    model.title = title;
    model.URLString = [wv mainFrameURL];
    model.estimatedProgress = [wv estimatedProgress];

    model.image = [wv documentViewImageWithAspectRatio:NSMakeSize(1, ASPECT_RATIO)];
    model.scaledImage = nil;
}


- (void)startObserveringTabController:(id)tc {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(tabControllerProgressDidChange:) name:FUTabControllerProgressDidChangeNotification object:tc];
    [nc addObserver:self selector:@selector(tabControllerDidFinishLoad:) name:FUTabControllerDidFinishLoadNotification object:tc];
}


- (void)stopObserveringTabController:(id)tc {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:FUTabControllerProgressDidChangeNotification object:tc];
    [nc removeObserver:self name:FUTabControllerDidFinishLoadNotification object:tc];
}


- (BOOL)isVertical {
    NSUInteger mask = [plugInAPI viewPlacementForPlugInIdentifier:[plugIn identifier]];
    return FUPlugInViewPlacementIsVerticalSplitView(mask) || FUPlugInViewPlacementIsDrawer(mask);
}


- (BOOL)isHorizontal {
    NSUInteger mask = [plugInAPI viewPlacementForPlugInIdentifier:[plugIn identifier]];
    return FUPlugInViewPlacementIsHorizontalSplitView(mask);
}

@synthesize listView;
@synthesize scrollView;
@synthesize plugIn;
@synthesize plugInAPI;
@synthesize tabModels;
@synthesize drawer;
@synthesize draggingTabController;
@end
