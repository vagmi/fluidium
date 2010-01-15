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

#import <Cocoa/Cocoa.h>
#import <TDAppKit/TDListView.h>

@class FUTabsPlugIn;
@protocol FUPlugInAPI;
@class FUTabModel;

@interface FUTabsViewController : NSViewController <TDListViewDataSource, TDListViewDelegate> {
    TDListView *listView;
    NSScrollView *scrollView;

    FUTabsPlugIn *plugIn;
    id <FUPlugInAPI>plugInAPI;
    NSMutableArray *tabModels;
    FUTabModel *selectedModel;
    
    NSInteger changeCount;

    NSDrawer *drawer;
    id draggingTabController;
}

- (void)viewWillAppear;
- (void)viewDidAppear;
- (void)viewWillDisappear;

- (IBAction)closeTabButtonClick:(id)sender;

@property (nonatomic, retain) IBOutlet TDListView *listView;
@property (nonatomic, retain) IBOutlet NSScrollView *scrollView;
@property (nonatomic, assign) FUTabsPlugIn *plugIn;
@property (nonatomic, assign) id <FUPlugInAPI>plugInAPI;
@property (nonatomic, retain) NSMutableArray *tabModels;
@property (nonatomic, retain) NSDrawer *drawer;
@property (nonatomic, retain) id draggingTabController;
@end
