//
//  FUTabsViewController.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/25/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "FUTabsViewController.h"
#import "FUPlugIn.h"
#import "FUPlugInAPI.h"
#import "FUTabsPlugIn.h"
#import "FUImageBrowserItem.h"
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>

@interface WebView ()
- (NSImage *)imageOfWebContent;
@end

@interface FUTabsViewController ()
- (NSArray *)webViews;
- (FUImageBrowserItem *)newImageBrowserItemForWebView:(WebView *)wv;
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
    self.imageBrowserView = nil;
    self.plugIn = nil;
    self.plugInAPI = nil;
    self.imageBrowserItems = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    
}


#pragma mark -
#pragma mark Public

- (void)viewDidAppear {
    NSArray *wvs = [self webViews];
    self.imageBrowserItems = [NSMutableArray arrayWithCapacity:[wvs count]];
    
    for (WebView *wv in wvs) {
        FUImageBrowserItem *item = [[self newImageBrowserItemForWebView:wv] autorelease];
        [imageBrowserItems addObject:item];
    }
    
    [imageBrowserView reloadData];
}


- (void)viewWillDisappear {
    self.imageBrowserItems = nil;
    [imageBrowserView reloadData];
}


#pragma mark -
#pragma mark IKImageBrowserDataSource

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)ib {
    return [imageBrowserItems count];
}


- (id /*IKImageBrowserItem*/)imageBrowser:(IKImageBrowserView *)ib itemAtIndex:(NSUInteger)i {
    return [imageBrowserItems objectAtIndex:i];
}


#pragma mark -
#pragma mark FUWindowControllerNotifcations

- (void)windowControllerDidOpenTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
    WebView *wv = [[self webViews] objectAtIndex:i];
    [imageBrowserItems insertObject:[[self newImageBrowserItemForWebView:wv] autorelease] atIndex:i];
}


- (void)windowControllerWillCloseTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
    [imageBrowserItems removeObjectAtIndex:i];
}


- (void)windowControllerDidChangeSelectedTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
    [imageBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
}


#pragma mark -
#pragma mark Private

- (NSArray *)webViews {
    return [plugInAPI webViewsForWindow:[self.view window]];
}


- (FUImageBrowserItem *)newImageBrowserItemForWebView:(WebView *)wv {
    FUImageBrowserItem *item = [[FUImageBrowserItem alloc] init];
    item.imageRepresentation = [wv imageOfWebContent];
    item.imageTitle = [wv mainFrameTitle];
    item.imageSubtitle = [wv mainFrameURL];
    return item;
}

@synthesize imageBrowserView;
@synthesize plugIn;
@synthesize plugInAPI;
@synthesize imageBrowserItems;
@end
