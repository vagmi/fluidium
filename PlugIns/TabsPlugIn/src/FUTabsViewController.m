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
#import "FUImageBrowserItem.h"
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>

@interface NSObject ()
- (void)setSelectedTabIndex:(NSInteger)i;
@end

@interface WebView ()
- (NSImage *)imageOfWebContent;
@end

@interface FUTabsViewController ()
- (NSArray *)webViews;
- (FUImageBrowserItem *)newImageBrowserItemForWebView:(WebView *)wv;
- (NSBitmapImageRep *)bitmapImageRepFromWebView:(WebView *)wv;
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
    [imageBrowserView setZoomValue:1.0];
    //[imageBrowserView setCellSize:NSMakeSize(600, 400)];
	[imageBrowserView setConstrainsToOriginalSize:NO];
	[imageBrowserView setContentResizingMask:NSViewHeightSizable];
	[imageBrowserView setAllowsEmptySelection:NO];
	[imageBrowserView setAllowsMultipleSelection:NO];
	[imageBrowserView setDelegate:self];
	[imageBrowserView setDataSource:self];
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
#pragma mark IKImageBrowserDelegate

- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)ib {
//    id wc = [[self.view window] windowController];
//    [wc setSelectedTabIndex:[[ib selectionIndexes] firstIndex]];
}


#pragma mark -
#pragma mark FUWindowControllerNotifcations

- (void)windowControllerDidOpenTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
    WebView *wv = [[self webViews] objectAtIndex:i];
    FUImageBrowserItem *item = [[self newImageBrowserItemForWebView:wv] autorelease];
    [imageBrowserItems insertObject:item atIndex:i];
    [imageBrowserView reloadData];
    
    id tc = [[n userInfo] objectForKey:@"FUTabController"];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(tabControllerDidFinishLoad:) name:FUTabControllerDidFinishLoadNotification object:tc];
}


- (void)windowControllerWillCloseTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
    [imageBrowserItems removeObjectAtIndex:i];
    [imageBrowserView reloadData];
    
    id tc = [[n userInfo] objectForKey:@"FUTabController"];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:FUTabControllerDidFinishLoadNotification object:tc];
}


- (void)windowControllerDidChangeSelectedTab:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
    [imageBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
}


#pragma mark -
#pragma mark FUTabControllerNotifcations

- (void)tabControllerDidFinishLoad:(NSNotification *)n {
    NSInteger i = [[[n userInfo] objectForKey:@"FUIndex"] integerValue];
    WebView *wv = [[self webViews] objectAtIndex:i];
    
    FUImageBrowserItem *item = [imageBrowserItems objectAtIndex:i];
    item.imageTitle = [wv mainFrameTitle];
    item.imageSubtitle = [wv mainFrameURL];
    item.imageRepresentation = [self bitmapImageRepFromWebView:wv];
    [imageBrowserView reloadData];
}


#pragma mark -
#pragma mark Private

- (NSArray *)webViews {
    return [plugInAPI webViewsForWindow:[self.view window]];
}


- (FUImageBrowserItem *)newImageBrowserItemForWebView:(WebView *)wv {
    FUImageBrowserItem *item = [[FUImageBrowserItem alloc] init];
    item.imageRepresentation = [self bitmapImageRepFromWebView:wv];
    item.imageTitle = [wv mainFrameTitle];
    item.imageSubtitle = [wv mainFrameURL];
    return item;
}


- (NSBitmapImageRep *)bitmapImageRepFromWebView:(WebView *)wv {
    NSImage *fullImg = [wv imageOfWebContent];
    if (!fullImg) return nil;

    NSSize fullSize = [fullImg size];
    
    CGFloat side = 0;
    CGFloat ratio = 0;
    
    if (fullSize.width < fullSize.height) {
        side = fullSize.width;
        ratio = fullSize.width / side;
    } else {
        side = fullSize.height;
        ratio = fullSize.height / side;
    }
    
    CGRect finalDisplayRect = CGRectMake(0, 0, side, side);

    CGFloat w = finalDisplayRect.size.width * ratio;
    CGFloat h = finalDisplayRect.size.height * ratio;
    
    CGFloat x = fullSize.width / 2.0 - w / 2.0;
    //CGFloat y = fullSize.height / 2.0 - h / 2.0;
    CGFloat y = 0;
    
    CGRect r = CGRectMake(x, y, w, h);
    NSLog(@"r: %@", NSStringFromRect(r));
    
    NSBitmapImageRep *imgRep = [[[NSBitmapImageRep alloc] initWithData:[fullImg TIFFRepresentation]] autorelease];
    if (!imgRep) return nil;
    
    CGImageRef cgImg = CGImageCreateWithImageInRect([imgRep CGImage], r);
    if (!cgImg) return nil;
    
    NSBitmapImageRep *finalImg = [[[NSBitmapImageRep alloc] initWithCGImage:cgImg] autorelease];
    CGImageRelease(cgImg);
    
    return finalImg;
}

@synthesize imageBrowserView;
@synthesize plugIn;
@synthesize plugInAPI;
@synthesize imageBrowserItems;
@end
