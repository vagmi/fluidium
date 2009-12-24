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

#import "FUPlugInAPIImpl.h"
#import "FUWindowController.h"
#import "FUDocumentController.h"
#import "FUTabController.h"
#import "FUApplication.h"
#import "FURecentURLController.h"
#import "FUWindow.h"
#import "FUWebView.h"
#import "FUPlugInWrapper.h"
#import "FUPlugInAPI.h"
#import <OmniAppKit/OAPreferenceController.h>
#import <WebKit/WebKit.h>

@interface FUPlugInAPIImpl ()
@property (nonatomic, copy, readwrite) NSString *version;
@property (nonatomic, copy, readwrite) NSString *plugInSupportDirPath;
@end

@implementation FUPlugInAPIImpl

- (id)init {
    if (self = [super init]) {
        self.version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        self.plugInSupportDirPath = [[[FUApplication instance] ssbSupportDirPath] stringByAppendingPathComponent:@"PlugIn Support"];
        [[NSFileManager defaultManager] createDirectoryAtPath:plugInSupportDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return self;
}


- (void)dealloc {
    self.version = nil;
    self.plugInSupportDirPath = nil;
    [super dealloc];
}


- (WebView *)frontWebView {
    return [[FUDocumentController instance] frontWebView];
}


- (WebView *)selectedWebViewForWindow:(NSWindow *)win {
    if (![win isMemberOfClass:[FUWindow class]]) {
        return nil;
    }
    
    FUWindowController *wc = (FUWindowController *)[win windowController];
    return [[wc selectedTabController] webView];
}


- (NSArray *)webViewsForWindow:(NSWindow *)win {
    if (![win isMemberOfClass:[FUWindow class]]) {
        return nil;
    }

    return [(FUWindowController *)[win windowController] webViews];
}


- (WebView *)newWebViewForPlugIn:(id <FUPlugIn>)plugIn {
    return [[FUWebView alloc] initWithFrame:NSZeroRect];
}


- (void)loadRequest:(NSURLRequest *)req destinationType:(FUPlugInDestinationType)type inForeground:(BOOL)inForeground {
    [[FUDocumentController instance] loadRequest:req destinationType:type inForeground:inForeground];
}


- (void)loadHTMLString:(NSString *)HTMLString destinationType:(FUPlugInDestinationType)type inForeground:(BOOL)inForeground {
    [[FUDocumentController instance] loadHTMLString:HTMLString destinationType:type inForeground:inForeground];
}


- (void)showStatusText:(NSString *)statusText {
    [[[FUDocumentController instance] frontTabController] setStatusText:statusText];
}


- (void)addRecentURL:(NSString *)URLString {
    [[FURecentURLController instance] addRecentURL:URLString];
}


- (void)showPreferencePaneForIdentifier:(NSString *)s {
    [[OAPreferenceController sharedPreferenceController] showPreferencesPanel:self];
    [[OAPreferenceController sharedPreferenceController] setCurrentClientRecord:[OAPreferenceController clientRecordWithIdentifier:s]];
}

@synthesize version;
@synthesize plugInSupportDirPath;
@end
