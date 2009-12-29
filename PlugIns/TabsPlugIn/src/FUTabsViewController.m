//
//  FUTabsViewController.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/25/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "FUTabsViewController.h"
#import "FUNotifications.h"
#import "FUPlugIn.h"
#import "FUPlugInAPI.h"
#import "FUTabsPlugIn.h"
#import "FUTabModel.h"
#import "TDTableView.h"
#import "FUTabTableRowView.h"
#import <WebKit/WebKit.h>

#define KEY_SELECTION_INDEXES @"selectionIndexes"
#define KEY_TAB_CONTROLLER @"FUTabController"
#define KEY_INDEX @"FUIndex"

@interface NSObject ()
// FUWindowController
- (void)setSelectedTabIndex:(NSInteger)i;
- (NSArray *)tabControllers;
- (void)startObserveringTabController:(id)tc;
- (void)stopObserveringTabController:(id)tc;
@end

@interface WebView ()
- (NSImage *)documentViewImageWithCurrentAspectRatio;
- (NSImage *)documentViewImageWithAspectRatio:(NSSize)size;
@end

@interface FUTabsViewController ()
- (NSArray *)webViews;
- (id)windowController;
- (void)updateTabModelLaterAtIndex:(NSNumber *)indexObj;
- (void)updateTabModelAtIndex:(NSInteger)i;
- (void)updateTabModel:(FUTabModel *)model fromWebView:(WebView *)wv;
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
    self.tableView = nil;
    self.plugIn = nil;
    self.plugInAPI = nil;
    self.tabModels = nil;
    self.drawer = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    tableView.backgroundColor = [NSColor colorWithDeviceWhite:.9 alpha:1.0];
}


#pragma mark -
#pragma mark Public

- (void)viewDidAppear {
    tableView.orientation = TDTableViewOrientationPortrait;
    
    NSArray *wvs = [self webViews];
    self.tabModels = [NSMutableArray arrayWithCapacity:[wvs count]];
    
    for (WebView *wv in wvs) {
        FUTabModel *model = [[[FUTabModel alloc] init] autorelease];
        [self updateTabModel:model fromWebView:wv];
        [tabModels addObject:model];
    }

    id wc = [self windowController];
    for (id tc in [wc tabControllers]) {
        [self startObserveringTabController:tc];
    }
    
    [tableView reloadData];
}


- (void)viewWillDisappear {
    self.tabModels = nil;
}


#pragma mark -
#pragma mark TDTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(TDTableView *)tv {
    return [tabModels count];
}


- (TDTableRowView *)tableView:(TDTableView *)tv viewForRowAtIndex:(NSInteger)i {
    FUTabTableRowView *rv = [tv dequeueReusableRowViewWithIdentifier:[FUTabTableRowView identifier]];
    
    if (!rv) {
        rv = [[[FUTabTableRowView alloc] init] autorelease];
    }
    
    rv.model = [tabModels objectAtIndex:i];
    [rv setNeedsDisplay:YES];
    
    return rv;
}


#pragma mark -
#pragma mark TDTableViewDelegate

- (CGFloat)tableView:(TDTableView *)tv heightForRowAtIndex:(NSInteger)i {
    CGFloat w = NSWidth([self.view frame]);
    return floor(w * .6);
}


- (void)tableView:(TDTableView *)tv willDisplayView:(TDTableRowView *)rv forRowAtIndex:(NSInteger)i {
    
}


- (void)tableView:(TDTableView *)tv didSelectRowAtIndex:(NSInteger)i {
    id wc = [self windowController];
    [wc setSelectedTabIndex:i];
}


#pragma mark -
#pragma mark NSSplitViewNotifications

- (void)splitViewDidResizeSubviews:(NSNotification *)n {
    if ([self isVertical]) {

    } else if ([self isHorizontal]) {

    }
}


#pragma mark -
#pragma mark FUWindowControllerNotifcations

- (void)windowControllerDidOpenTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:KEY_INDEX] integerValue];
    WebView *wv = [[self webViews] objectAtIndex:i];
    FUTabModel *model = [[[FUTabModel alloc] init] autorelease];
    [self updateTabModel:model fromWebView:wv];
    [tabModels insertObject:model atIndex:i];
    [tableView reloadData];
    
    id tc = [[n userInfo] objectForKey:KEY_TAB_CONTROLLER];
    [self startObserveringTabController:tc];
}


- (void)windowControllerWillCloseTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:KEY_INDEX] integerValue];
    [tabModels removeObjectAtIndex:i];
    [tableView reloadData];
    
    id tc = [[n userInfo] objectForKey:KEY_TAB_CONTROLLER];
    [self stopObserveringTabController:tc];
}


- (void)windowControllerDidChangeSelectedTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:KEY_INDEX] integerValue];
    [tableView setSelectedRowIndex:i];
    
//    if (i < [tabModels count]) {
//        [self updateTabModelAtIndex:i];
//    }
}


#pragma mark -
#pragma mark FUTabControllerNotifcations

- (void)tabControllerProgressDidChange:(NSNotification *)n {
    if (0 == ++changeCount % 3) { // only update web image every third notification
        NSInteger i = [[[n userInfo] objectForKey:KEY_INDEX] integerValue];
        [self updateTabModelAtIndex:i];
    }
}


//- (void)timerFired:(NSTimer *)t {
//    [self updateTabModelLaterAtIndex:[t userInfo]];
//}


- (void)tabControllerDidFinishLoad:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:KEY_INDEX] integerValue];
    [self updateTabModelAtIndex:i];
    
    //    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired:) userInfo:[NSNumber numberWithInteger:i] repeats:YES];
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


- (void)updateTabModelLaterAtIndex:(NSNumber *)indexObj {
    [self updateTabModelAtIndex:[indexObj integerValue]];
}


- (void)updateTabModelAtIndex:(NSInteger)i {
    WebView *wv = [[self webViews] objectAtIndex:i];
    
    FUTabModel *model = [tabModels objectAtIndex:i];
    [self updateTabModel:model fromWebView:wv];
}


- (void)updateTabModel:(FUTabModel *)model fromWebView:(WebView *)wv {
    model.image = [wv documentViewImageWithAspectRatio:NSMakeSize(1, 1)];

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

@synthesize tableView;
@synthesize plugIn;
@synthesize plugInAPI;
@synthesize tabModels;
@synthesize drawer;
@end
