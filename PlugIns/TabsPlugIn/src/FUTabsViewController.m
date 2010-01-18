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
#import <Fluidium/FUPlugIn.h>
#import <Fluidium/FUPlugInAPI.h>
#import "FUTabsPlugIn.h"
#import "FUTabModel.h"
#import "FUTabListItem.h"
#import "WebURLsWithTitles.h"
#import <WebKit/WebKit.h>
#import <Fluidium/FUWindowController.h>
#import <Fluidium/FUTabController.h>
#import <Fluidium/FUNotifications.h>

#define KEY_SELECTION_INDEXES @"selectionIndexes"
#define KEY_TAB_CONTROLLER @"FUTabController"
#define KEY_INDEX @"FUIndex"

#define ASPECT_RATIO .7

#define TDTabPboardType @"TDTabPboardType"

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
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

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
    [listView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];

    // setup ui
    listView.displaysClippedItems = YES;
}


- (IBAction)closeTabButtonClick:(id)sender {
    FUWindowController *wc = [self windowController];
    FUTabController *tc = [wc tabControllerAtIndex:[sender tag]];
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


- (TDListItem *)listView:(TDListView *)lv viewForItemAtIndex:(NSUInteger)i {
    FUTabListItem *itemView = [lv dequeueReusableItemWithIdentifier:[FUTabListItem reuseIdentifier]];
    
    if (!itemView) {
        itemView = [[[FUTabListItem alloc] init] autorelease];
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


- (void)listView:(TDListView *)lv willDisplayView:(TDListItem *)itemView forItemAtIndex:(NSUInteger)i {
    
}


- (void)listView:(TDListView *)lv didSelectItemAtIndex:(NSUInteger)i {
    FUWindowController *wc = [self windowController];
    [wc setSelectedTabIndex:i];
}


- (void)listView:(TDListView *)lv emptyAreaWasDoubleClicked:(NSEvent *)evt {
    [[[self.view window] windowController] openTab:self];
}


#pragma mark -
#pragma mark TDListViewDelegate Drag

- (BOOL)listView:(TDListView *)lv writeItemAtIndex:(NSUInteger)i toPasteboard:(NSPasteboard *)pboard {
    FUWindowController *wc = [self windowController];
    self.draggingTabController = [wc tabControllerAtIndex:i];
    NSURL *URL = [NSURL URLWithString:[draggingTabController URLString]];

    if (URL) {
        [pboard declareTypes:[NSArray arrayWithObjects:TDTabPboardType, TDListItemPboardType, nil] owner:self];
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
        return NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}


- (BOOL)listView:(TDListView *)lv acceptDrop:(id <NSDraggingInfo>)draggingInfo index:(NSUInteger)i dropOperation:(TDListViewDropOperation)dropOperation {
    NSPasteboard *pboard = [draggingInfo draggingPasteboard];
    
    FUWindowController *wc = [self windowController];
    NSArray *types = [pboard types];
    NSURL *URL = nil;
    if ([types containsObject:TDTabPboardType]) {
        [wc removeTabController:draggingTabController];
        [wc addTabController:draggingTabController atIndex:i];
        self.draggingTabController = nil;

        [self updateAllTabModelsFromIndex:i];
        [wc setSelectedTabIndex:i];
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
            [[self windowController] loadRequest:[NSURLRequest requestWithURL:URL] inNewTab:NO atIndex:i andSelect:YES];
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
    
    FUTabController *tc = [[n userInfo] objectForKey:KEY_TAB_CONTROLLER];
    [self startObserveringTabController:tc];
}


- (void)windowControllerWillCloseTab:(NSNotification *)n {
    FUTabController *tc = [[n userInfo] objectForKey:KEY_TAB_CONTROLLER];
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
    NSInteger i = [[[n userInfo] objectForKey:KEY_INDEX] integerValue];
    [self updateTabModelAtIndex:i];
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
    
    FUWindowController *wc = [self windowController];
    for (FUTabController *tc in [wc tabControllers]) {
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
    
    CGFloat progress = [wv estimatedProgress];

    // this handles cases like Gmail ajax refresh where the page can sit at 100% forever cuz there's not 'didFinishLoad' fired for ajax refreshes.
    if (progress > .95) {
        model.loading = NO;
        model.estimatedProgress = 0;
        [self performSelector:@selector(updateTabModelLaterAtIndex:) withObject:[NSNumber numberWithInteger:i] afterDelay:2];
    }

    model.estimatedProgress = progress;

    if ([model wantsNewImage]) {
        model.image = [wv documentViewImageWithAspectRatio:NSMakeSize(1, ASPECT_RATIO)];
        model.scaledImage = nil;
    }
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
