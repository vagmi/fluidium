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

@class FUWindowController;
@class FUWebView;
@class FUJavaScriptBridge;
@class WebInspector;

@interface FUTabController : NSObject {
    FUWindowController *windowController;
    NSView *view;
    FUWebView *webView;
    FUJavaScriptBridge *javaScriptBridge;
    NSString *URLString;
    NSString *initialURLString;
    NSString *title;
    NSImage *favicon;
    NSString *statusText;
    NSDictionary *clickElementInfo;
    NSDictionary *hoverElementInfo;
    WebInspector *inspector;

    BOOL lastLoadFailed;
    
    BOOL isProcessing; // the 'is' is necessary here to match PSMTabBarControl
    BOOL canReload;
    BOOL didReceiveTitle;
}

- (id)initWithWindowController:(FUWindowController *)wc;

- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)reload:(id)sender;
- (IBAction)stopLoading:(id)sender;

- (IBAction)goToLocation:(id)sender;

// context menu actions
- (IBAction)openLinkInNewTabFromMenu:(id)sender;
- (IBAction)openLinkInNewWindowFromMenu:(id)sender;
- (IBAction)openFrameInNewWindowFromMenu:(id)sender;
- (IBAction)openImageInNewWindowFromMenu:(id)sender;
- (IBAction)searchWebFromMenu:(id)sender;
- (IBAction)downloadLinkAsFromMenu:(id)sender;

- (IBAction)showWebInspector:(id)sender;
- (IBAction)showErrorConsole:(id)sender;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)actualSize:(id)sender;

- (BOOL)canZoomIn;
- (BOOL)canZoomOut;
- (BOOL)canActualSize;

- (BOOL)canReload;

- (void)loadView;
- (BOOL)isViewLoaded;

- (void)loadRequest:(NSURLRequest *)req;

@property (nonatomic, assign, readonly) FUWindowController *windowController; // weak ref
@property (nonatomic, retain) NSView *view;
@property (nonatomic, retain) FUWebView *webView;
@property (nonatomic, retain) FUJavaScriptBridge *javaScriptBridge;
@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, copy) NSString *initialURLString;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, retain) NSImage *favicon;
@property (nonatomic, copy) NSString *statusText;
@property (nonatomic, retain) NSDictionary *clickElementInfo;
@property (nonatomic, retain) NSDictionary *hoverElementInfo;
@property (nonatomic, retain) WebInspector *inspector;
@property (nonatomic) BOOL lastLoadFailed;

@property (nonatomic) BOOL isProcessing;
@property (nonatomic) BOOL canReload;
@end
