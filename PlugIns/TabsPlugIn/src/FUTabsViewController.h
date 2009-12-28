//
//  FUTabsViewController.h
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/25/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IKImageBrowserView;
@class FUTabsPlugIn;
@protocol FUPlugInAPI;

@interface FUTabsViewController : NSViewController {
    IKImageBrowserView *imageBrowserView;
    FUTabsPlugIn *plugIn;
    id <FUPlugInAPI>plugInAPI;
    NSMutableArray *imageBrowserItems;
    
    NSInteger changeCount;

    NSDrawer *drawer;
}

- (void)viewDidAppear;
- (void)viewWillDisappear;

@property (nonatomic, retain) IBOutlet IKImageBrowserView *imageBrowserView;
@property (nonatomic, assign) FUTabsPlugIn *plugIn;
@property (nonatomic, assign) id <FUPlugInAPI>plugInAPI;
@property (nonatomic, retain) NSMutableArray *imageBrowserItems;
@property (nonatomic, retain) NSDrawer *drawer;
@end
