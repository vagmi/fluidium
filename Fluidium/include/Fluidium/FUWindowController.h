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

@class WebView;
@class TDUberView;
@class PSMTabBarControl;
@class FUViewSourceWindowController;
@class FUTabController;
@class FUProgressComboBox;
@class FUShortcutController;
@class FUBookmark;
@class TDLine;

@interface FUWindowController : NSWindowController 
#if FU_BUILD_TARGET_SNOW_LEOPARD
<NSToolbarDelegate>
#endif
{
    NSSplitView *locationSplitView;
    FUProgressComboBox *locationComboBox;
    NSSearchField *searchField;
    
    NSView *tabContainerView;
    PSMTabBarControl *tabBar;
    TDLine *emptyTabBarLine;
    NSView *bookmarkBar;
    TDUberView *uberView;
    NSView *statusBar;
    NSTextField *statusTextField;
    NSProgressIndicator *statusProgressIndicator;
    
    NSView *findPanelView;
    NSSearchField *findPanelSearchField;
    
    NSWindow *editBookmarkSheet;
    FUBookmark *editingBookmark;

    NSTabView *tabView;
    FUTabController *departingTabController;
    NSUInteger draggingTabIndex;
 
    BOOL typingInFindPanel;
    NSString *findPanelTerm;
    
    FUViewSourceWindowController *viewSourceController;
    FUShortcutController *shortcutController;

    NSMutableSet *tabControllers;
    FUTabController *selectedTabController;
    
    NSString *currentTitle;
    
    BOOL suppressNextFrameStringSave;
    BOOL displayingMatchingRecentURLs;
    
    // the index of the just closed tab if it was selected. otherwise -1
    NSInteger closingSelectedTabIndex;
    
    // the index of the tab selected prior to the current selected index
    NSInteger priorSelectedTabIndex;
}

- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)reload:(id)sender;
- (IBAction)stopLoading:(id)sender;
- (IBAction)goHome:(id)sender;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)actualSize:(id)sender;

- (IBAction)goToLocation:(id)sender;
- (IBAction)openLocation:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)openSearch:(id)sender;

- (IBAction)viewSource:(id)sender;
- (IBAction)emptyCache:(id)sender;
- (IBAction)toggleToolbarShown:(id)sender;

- (IBAction)closeWindow:(id)sender;

- (IBAction)openTab:(id)sender;
- (IBAction)closeTab:(id)sender;
- (IBAction)selectNextTab:(id)sender;
- (IBAction)selectPreviousTab:(id)sender;

- (IBAction)showFindPanel:(id)sender;
- (IBAction)hideFindPanel:(id)sender;
- (IBAction)find:(id)sender;
- (IBAction)useSelectionForFind:(id)sender;
- (IBAction)jumpToSelection:(id)sender;

- (IBAction)addBookmark:(id)sender;
- (IBAction)bookmarkClicked:(id)sender;
- (IBAction)endEditBookmark:(id)sender;

- (IBAction)showWebInspector:(id)sender;
- (IBAction)showErrorConsole:(id)sender;

- (void)runEditTitleSheetForBookmark:(FUBookmark *)bmark;

- (BOOL)isFindPanelVisible;

- (FUTabController *)loadRequestInSelectedTab:(NSURLRequest *)req;
- (FUTabController *)loadRequest:(NSURLRequest *)req inNewTabAndSelect:(BOOL)select; // shouldCreate=YES, index=count
- (FUTabController *)loadRequest:(NSURLRequest *)req inNewTab:(BOOL)shouldCreate atIndex:(NSInteger)i andSelect:(BOOL)select;

- (FUTabController *)addNewTabAndSelect:(BOOL)select;
- (FUTabController *)addNewTabAtIndex:(NSInteger)i andSelect:(BOOL)select;

- (void)addTabController:(FUTabController *)tc;
- (void)addTabController:(FUTabController *)tc atIndex:(NSInteger)i;

- (BOOL)removeTabController:(FUTabController *)tc;
- (void)selectTabController:(FUTabController *)tc;

- (FUTabController *)tabControllerAtIndex:(NSInteger)i;
- (FUTabController *)tabControllerForWebView:(WebView *)wv;
- (NSInteger)indexOfTabController:(FUTabController *)tc;

- (NSArray *)webViews;

@property (nonatomic) NSInteger selectedTabIndex;

@property (nonatomic, retain) IBOutlet NSSplitView *locationSplitView;
@property (nonatomic, retain) IBOutlet FUProgressComboBox *locationComboBox;
@property (nonatomic, retain) IBOutlet NSSearchField *searchField;
@property (nonatomic, retain) IBOutlet NSView *tabContainerView;
@property (nonatomic, retain) IBOutlet PSMTabBarControl *tabBar;
@property (nonatomic, retain) IBOutlet TDLine *emptyTabBarLine;
@property (nonatomic, retain) IBOutlet NSView *bookmarkBar;
@property (nonatomic, retain) IBOutlet TDUberView *uberView;
@property (nonatomic, retain) IBOutlet NSView *statusBar;
@property (nonatomic, retain) IBOutlet NSTextField *statusTextField;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *statusProgressIndicator;
@property (nonatomic, retain) IBOutlet NSView *findPanelView;
@property (nonatomic, retain) IBOutlet NSSearchField *findPanelSearchField;
@property (nonatomic, retain) IBOutlet NSWindow *editBookmarkSheet;
@property (nonatomic, retain) FUBookmark *editingBookmark;
@property (nonatomic, retain) NSTabView *tabView;
@property (nonatomic, assign) FUTabController *departingTabController; // weak ref
@property (nonatomic, retain) FUViewSourceWindowController *viewSourceController;
@property (nonatomic, retain) FUShortcutController *shortcutController;
@property (nonatomic, retain) NSMutableSet *tabControllers;
@property (nonatomic, retain, readonly) FUTabController *selectedTabController; // use selectedTabIndex or selectTabController: to set
@property (nonatomic, copy) NSString *currentTitle;
@property (nonatomic, copy) NSString *findPanelTerm;
@property (nonatomic, getter=isTypingInFindPanel) BOOL typingInFindPanel;

@property (nonatomic) BOOL suppressNextFrameStringSave;
@end
