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
@class FUActivation;
@protocol FUPlugIn;

typedef enum {
    FUPlugInDestinationTypeWindow,
    FUPlugInDestinationTypeTab
} FUPlugInDestinationType;

@protocol FUPlugInAPI
- (NSString *)version;
- (NSString *)defaultUserAgentString;
- (NSArray *)allUserAgentStrings;

- (BOOL)isFullScreen;

- (WebView *)frontWebView;

- (WebView *)selectedWebViewForWindow:(NSWindow *)win;
- (NSArray *)webViewsForWindow:(NSWindow *)win;
- (NSArray *)webViewsForDrawer:(NSDrawer *)drawer;

// create and setup a new WebView for use in a plugin view controller. must be released by caller.
- (WebView *)newWebViewForPlugIn:(id <FUPlugIn>)plugIn;

- (NSString *)plugInSupportDirPath;

- (NSUInteger)viewPlacementForPlugInIdentifier:(NSString *)s;

- (void)loadRequest:(NSURLRequest *)request; // prefers tabs
- (void)loadRequest:(NSURLRequest *)request destinationType:(FUPlugInDestinationType)type; // respects FUSelectTabsAndWindowsAsCreated
- (void)loadRequest:(NSURLRequest *)request destinationType:(FUPlugInDestinationType)type inForeground:(BOOL)inForeground;

- (void)downloadRequest:(NSURLRequest *)req directory:(NSString *)dirPath filename:(NSString *)filename;

- (void)showStatusText:(NSString *)statusText;

// TODO move to Friend category?
- (void)addRecentURL:(NSString *)URLString;
- (void)addMatchingRecentURL:(NSString *)URLString;
- (void)removeRecentURL:(NSString *)URLString;
- (NSArray *)recentURLs;
- (NSArray *)matchingRecentURLs;
- (void)resetRecentURLs;
- (void)resetMatchingRecentURLs;

- (void)showPreferencePaneForIdentifier:(NSString *)s;
@end
