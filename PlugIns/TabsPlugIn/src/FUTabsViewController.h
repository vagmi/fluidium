//
//  FUTabsViewController.h
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/25/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TDTableView.h"

@class FUTabsPlugIn;
@protocol FUPlugInAPI;

@interface FUTabsViewController : NSViewController <TDTableViewDataSource, TDTableViewDelegate> {
    TDTableView *tableView;

    FUTabsPlugIn *plugIn;
    id <FUPlugInAPI>plugInAPI;
    NSMutableArray *tabModels;
    
    NSInteger changeCount;

    NSDrawer *drawer;
}

- (void)viewDidAppear;
- (void)viewWillDisappear;

@property (nonatomic, retain) IBOutlet TDTableView *tableView;
@property (nonatomic, assign) FUTabsPlugIn *plugIn;
@property (nonatomic, assign) id <FUPlugInAPI>plugInAPI;
@property (nonatomic, retain) NSMutableArray *tabModels;
@property (nonatomic, retain) NSDrawer *drawer;
@end
