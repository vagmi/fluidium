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
#import <WebKit/WebKit.h>

@interface NSObject ()
// FUWindowController
- (void)setSelectedTabIndex:(NSInteger)i;
- (NSArray *)tabControllers;
- (void)startObserveringTabController:(id)tc;
- (void)stopObserveringTabController:(id)tc;
@end

@interface WebView ()
- (NSImage *)imageOfWebContentWithAspectRatio:(NSSize)size;
- (NSImage *)imageOfWebContent;
- (NSImage *)squareImageOfWebContent;
- (NSImage *)landscapeImageOfWebContent;
- (NSBitmapImageRep *)bitmapOfWebContent;
- (NSBitmapImageRep *)landscapeBitmapOfWebContent;
- (NSBitmapImageRep *)squareBitmapOfWebContent;
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
    self.modelController = nil;
    self.scrollView = nil;
    self.collectionView = nil;
    self.plugIn = nil;
    self.plugInAPI = nil;
    self.tabModels = nil;
    self.drawer = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [collectionView setSelectable:YES];
    [collectionView setBackgroundColors:[NSArray arrayWithObject:[NSColor colorWithDeviceWhite:.95 alpha:1]]];
    
    [collectionView addObserver:self forKeyPath:@"selectionIndexes" options:NSKeyValueObservingOptionNew context:NULL];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)ctx {
    if ([@"selectionIndexes" isEqualToString:keyPath]) {
        id wc = [self windowController];
        [wc setSelectedTabIndex:[[collectionView selectionIndexes] firstIndex]];
    }
}


- (void)splitViewDidResizeSubviews:(NSNotification *)n {
    if ([self isVertical]) {
        CGFloat w = [scrollView contentSize].width;
        NSSize size = NSMakeSize(w, w * .59);
        [collectionView setMinItemSize:size];
        [collectionView setMaxItemSize:size];
    } else if ([self isHorizontal]) {
        CGFloat h = [scrollView contentSize].height;
        NSSize size = NSMakeSize(h * 1.69, h);
        [collectionView setMinItemSize:size];
        [collectionView setMaxItemSize:size];
    }
}


#pragma mark -
#pragma mark Public

- (void)viewDidAppear {
    if ([self isVertical]) {
        [collectionView setMaxNumberOfRows:0];
        [collectionView setMaxNumberOfColumns:1];
    } else if ([self isHorizontal]) {
        [collectionView setMaxNumberOfRows:1];
        [collectionView setMaxNumberOfColumns:0];
    }
    
    [collectionView setMinItemSize:NSMakeSize(100, 59)];
    CGFloat w = [scrollView contentSize].width;
    [collectionView setMaxItemSize:NSMakeSize(w, w * .59)];
    
    NSArray *wvs = [self webViews];
    self.tabModels = [NSMutableArray arrayWithCapacity:[wvs count]];
    
    for (WebView *wv in wvs) {
        FUTabModel *model = [[[FUTabModel alloc] init] autorelease];
        [self updateTabModel:model fromWebView:wv];
        //[tabModels addObject:model];
        [modelController addObject:model];
    }

    id wc = [self windowController];
    for (id tc in [wc tabControllers]) {
        [self startObserveringTabController:tc];
    }
}


- (void)viewWillDisappear {
    self.tabModels = nil;
}


#pragma mark -
#pragma mark FUWindowControllerNotifcations

- (void)windowControllerDidOpenTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
    WebView *wv = [[self webViews] objectAtIndex:i];
    FUTabModel *model = [[[FUTabModel alloc] init] autorelease];
    [self updateTabModel:model fromWebView:wv];
    [modelController insertObject:model atArrangedObjectIndex:i];
    
    id tc = [[n userInfo] objectForKey:@"FUTabController"];
    [self startObserveringTabController:tc];
}


- (void)windowControllerWillCloseTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
    [modelController removeObjectAtArrangedObjectIndex:i];
    
    id tc = [[n userInfo] objectForKey:@"FUTabController"];
    [self stopObserveringTabController:tc];
}


- (void)windowControllerDidChangeSelectedTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
    [collectionView setSelectionIndexes:[NSIndexSet indexSetWithIndex:i]];
    
//    if (i < [tabModels count]) {
//        [self updateTabModelAtIndex:i];
//    }
}


#pragma mark -
#pragma mark FUTabControllerNotifcations

- (void)tabControllerProgressDidChange:(NSNotification *)n {
    if (0 == ++changeCount % 3) { // only update web image every third notification
        NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
        [self updateTabModelAtIndex:i];
    }
}


- (void)tabControllerDidFinishLoad:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
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


- (void)updateTabModelLaterAtIndex:(NSNumber *)indexObj {
    [self updateTabModelAtIndex:[indexObj integerValue]];
}


- (void)updateTabModelAtIndex:(NSInteger)i {
    WebView *wv = [[self webViews] objectAtIndex:i];
    
    FUTabModel *model = [tabModels objectAtIndex:i];
    [self updateTabModel:model fromWebView:wv];
}


- (void)updateTabModel:(FUTabModel *)model fromWebView:(WebView *)wv {
    model.image = [wv imageOfWebContentWithAspectRatio:NSMakeSize(1, .5)];
    NSString *title = [wv mainFrameTitle];
    if (![title length]) {
        title = NSLocalizedString(@"Untitled", @"");
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

@synthesize modelController;
@synthesize scrollView;
@synthesize collectionView;
@synthesize plugIn;
@synthesize plugInAPI;
@synthesize tabModels;
@synthesize drawer;
@end
