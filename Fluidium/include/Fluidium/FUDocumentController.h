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
//#import <Growl/Growl.h>

@class FUDocument;
@class FUWindowController;
@class FUTabController;
@class WebView;
@class WebFrame;

typedef enum {
    FUDestinationTypeWindow,
    FUDestinationTypeTab
} FUDestinationType;

//@interface FUDocumentController : NSDocumentController <GrowlApplicationBridgeDelegate> {
@interface FUDocumentController : NSDocumentController {
    NSWindow *hiddenWindow;
}

+ (FUDocumentController *)instance;

- (IBAction)toggleTabBarShown:(id)sender;
- (IBAction)toggleBookmarkBarShown:(id)sender;
- (IBAction)toggleStatusBarShown:(id)sender;

- (IBAction)openLocation:(id)sender;
- (IBAction)openSearch:(id)sender;
- (IBAction)newTab:(id)sender;
- (IBAction)newBackgroundTab:(id)sender;

- (IBAction)dockMenuItemClick:(id)sender;

- (FUDocument *)openDocumentWithURL:(NSString *)s makeKey:(BOOL)makeKey;

- (FUTabController *)loadURL:(NSString *)s; // prefers tabs
- (FUTabController *)loadURL:(NSString *)s destinationType:(FUDestinationType)type; // respects FUSelectNewWindowsOrTabsAsCreated
- (FUTabController *)loadURL:(NSString *)s destinationType:(FUDestinationType)type inForeground:(BOOL)inForeground;

- (void)downloadRequest:(NSURLRequest *)req directory:(NSString *)dirPath filename:(NSString *)filename;

- (WebFrame *)findFrameNamed:(NSString *)name outTabController:(FUTabController **)outTabController;

- (FUDocument *)frontDocument;
- (FUWindowController *)frontWindowController;
- (FUTabController *)frontTabController;
- (WebView *)frontWebView;

- (void)saveSession;
- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError;

@property (nonatomic, assign) NSWindow *hiddenWindow; // weak ref
@end
