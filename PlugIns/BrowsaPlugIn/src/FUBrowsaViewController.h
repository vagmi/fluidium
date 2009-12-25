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

#import <Foundation/Foundation.h>

@class WebView;
@class FUBrowsaComboBox;
@class FUBrowsaPlugIn;

@protocol FUPlugInAPI;

@interface FUBrowsaViewController : NSViewController {
    WebView *webView;
    NSView *navBar;
    FUBrowsaComboBox *locationComboBox;
    NSButton *homeButton;
    
    id <FUPlugInAPI>plugInAPI;
    FUBrowsaPlugIn *plugIn;
    
    NSString *URLString;
    NSString *initialURLString;
    NSString *title;
    NSImage *favicon;
    NSString *statusText;
    NSDictionary *clickElementInfo;
    NSDictionary *hoverElementInfo;
    
    BOOL lastLoadFailed;
    
    BOOL isProcessing;
    BOOL canReload;

    CGFloat progress;
    BOOL hasUpdatedNavBar;
    BOOL displayingMatchingRecentURLs;
}

- (IBAction)goHome:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)reload:(id)sender;
- (IBAction)stopLoading:(id)sender;

- (IBAction)goToLocation:(id)sender;

- (IBAction)showNavBar:(id)sender;
- (IBAction)hideNavBar:(id)sender;

// context menu actions
- (IBAction)openLinkInNewTabFromMenu:(id)sender;
- (IBAction)openLinkInNewWindowFromMenu:(id)sender;
- (IBAction)openFrameInNewWindowFromMenu:(id)sender;
- (IBAction)openImageInNewWindowFromMenu:(id)sender;
- (IBAction)searchWebFromMenu:(id)sender;
- (IBAction)downloadLinkAsFromMenu:(id)sender;

- (void)didAppear;
- (void)willDisappear;

- (BOOL)canReload;

- (void)loadRequest:(NSURLRequest *)req;

@property (nonatomic, retain) id <FUPlugInAPI>plugInAPI;
@property (nonatomic, retain) FUBrowsaPlugIn *plugIn;
@property (nonatomic, retain) IBOutlet WebView *webView;
@property (nonatomic, retain) IBOutlet NSView *navBar;
@property (nonatomic, retain) IBOutlet FUBrowsaComboBox *locationComboBox;
@property (nonatomic, retain) IBOutlet NSButton *homeButton;
@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, copy) NSString *initialURLString;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, retain) NSImage *favicon;
@property (nonatomic, copy) NSString *statusText;
@property (nonatomic, retain) NSDictionary *clickElementInfo;
@property (nonatomic, retain) NSDictionary *hoverElementInfo;
@property (nonatomic) BOOL lastLoadFailed;
@property (nonatomic) BOOL isProcessing;
@property (nonatomic) BOOL canReload;
@property (nonatomic) CGFloat progress;
@end
