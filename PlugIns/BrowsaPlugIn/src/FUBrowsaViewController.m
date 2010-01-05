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

#import "FUBrowsaViewController.h"
#import "FUBrowsaPlugIn.h"
#import "FUBrowsaPreferencesViewController.h"
#import "FUUtils.h"
#import "FUNotifications.h"
#import "FUPlugInAPI.h"
#import "FUBrowsaActivation.h"
#import "FUBrowsaComboBox.h"
#import "NSString+FUAdditions.h"
#import "NSEvent+FUAdditions.h"
#import "DOMNode+FUAdditions.h"
#import "WebIconDatabase.h"
#import "WebIconDatabase+FUAdditions.h"
#import "WebViewPrivate.h"
#import <WebKit/WebKit.h>

NSString *const kFUZoomTextOnlyKey = @"FUZoomTextOnly";
NSString *const kFUTargetedClicksCreateTabsKey = @"FUTargetedClicksCreateTabs";

typedef enum {
    WebNavigationTypePlugInRequest = WebNavigationTypeOther + 1
} WebExtraNavigationType;

@interface WebView (FUAdditions)
+ (BOOL)_canHandleRequest:(NSURLRequest *)req;
@end

@interface NSObject (FUCompiler)
- (id)frontTabController;
- (void)handleCommandClick:(id)activation request:(NSURLRequest *)req forWindow:(NSWindow *)win;
@end

@interface FUBrowsaViewController ()
- (void)setUpWebView;
- (void)updateNavBar;
- (void)handleLoadFail:(NSError *)err;
- (BOOL)willRetryWithTLDAdded:(WebView *)wv;
- (NSImage *)defaultFavicon;

- (BOOL)shouldHandleRequest:(NSURLRequest *)req;
- (BOOL)insertItem:(NSMenuItem *)item intoMenuItems:(NSMutableArray *)items afterItemWithTag:(NSInteger)tag;
- (NSInteger)indexOfItemWithTag:(NSUInteger)tag inMenuItems:(NSArray *)items;
- (NSString *)currentSelectionFromWebView;
- (BOOL)zoomTextOnly;

- (void)displayEstimatedProgress;
- (void)clearProgressInFuture;
- (void)clearProgress;    

- (NSArray *)recentURLs;
- (NSArray *)matchingRecentURLs;
- (void)addRecentURL:(NSString *)s;
- (void)addMatchingRecentURL:(NSString *)s;

- (void)updateUserAgentString;
- (void)browsaUserAgentStringDidChange:(NSNotification *)n;
@end

@implementation FUBrowsaViewController

- (id)init {
    return [self initWithNibName:@"FUBrowsaView" bundle:[NSBundle bundleForClass:[self class]]];
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    if (self = [super initWithNibName:name bundle:b]) {        
        // necessary to prevent bindings exceptions
        self.URLString = @"";
        self.title = NSLocalizedString(@"Untitled", @"");
        self.favicon = [self defaultFavicon];
        self.statusText = @"";
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // taking some extra paranoid steps here with the webView to prevent crashing 
    // on one of the many callbacks/notifications that can be sent to or received by webviews
    // when the tab closes
    [[NSNotificationCenter defaultCenter] removeObserver:webView];
    [webView stopLoading:self];
    [webView setFrameLoadDelegate:nil];
    [webView setResourceLoadDelegate:nil];
    [webView setDownloadDelegate:nil];
    [webView setPolicyDelegate:nil];
    [webView setUIDelegate:nil];
        
    self.plugInAPI = nil;
    self.plugIn = nil;
    self.view = nil;
    self.webView = nil;
    self.homeButton = nil;
    self.URLString = nil;
    self.initialURLString = nil;
    self.title = nil;
    self.favicon = nil;
    self.statusText = nil;
    self.clickElementInfo = nil;
    self.hoverElementInfo = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUBrowsaViewController %@>", title];
}


#pragma mark -
#pragma mark Actions

- (IBAction)goHome:(id)sender {
    self.URLString = plugIn.homeURLString;
    [self goToLocation:sender];
}


- (IBAction)goBack:(id)sender {
    [webView goBack:sender];
}


- (IBAction)goForward:(id)sender {
    [webView goForward:sender];
}


- (IBAction)reload:(id)sender {
    if (self.lastLoadFailed) {
        [self goToLocation:self];
    } else {
        [webView reload:sender];
    }
}


- (IBAction)stopLoading:(id)sender {
    [webView stopLoading:sender];
}


- (IBAction)goToLocation:(id)sender {
    if (![URLString length]) {
        return;
    }
    
    self.title = NSLocalizedString(@"Loading...", @"");
    self.URLString = [URLString stringByEnsuringURLSchemePrefix];
    [webView setMainFrameURL:URLString];
}


- (IBAction)showNavBar:(id)sender {
    NSRect frame = [self.view frame];
    CGFloat h = NSHeight([navBar bounds]);
    NSRect navFrame = NSMakeRect(0, NSMaxY(frame) - h, NSWidth(frame), h);
    
    NSRect webFrame = frame;
    webFrame.size.height -= h;
    
    [webView setFrame:webFrame];
    [navBar setFrame:navFrame];
    
    [self.view addSubview:navBar];
    [self.view setNeedsDisplay:YES];
    [webView setNeedsDisplay:YES];
    [navBar setNeedsDisplay:YES];
}
    

- (IBAction)hideNavBar:(id)sender {
    if (![URLString length]) return;

    [navBar removeFromSuperview];
    [webView setFrame:[self.view frame]];
    [self.view setNeedsDisplay:YES];
    [webView setNeedsDisplay:YES];
}


- (IBAction)zoomIn:(id)sender {
    if ([self zoomTextOnly]) {
        [webView makeTextLarger:sender];
    } else {
        [webView zoomPageIn:sender];
    }
}


- (IBAction)zoomOut:(id)sender {
    if ([self zoomTextOnly]) {
        [webView makeTextSmaller:sender];
    } else {
        [webView zoomPageOut:sender];
    }
}


- (IBAction)actualSize:(id)sender {
    if ([self zoomTextOnly]) {
        [webView makeTextStandardSize:sender];
    } else {
        [webView resetPageZoom:sender];
    }
}


- (BOOL)canZoomIn {
    if ([self zoomTextOnly]) {
        return [webView canMakeTextLarger];
    } else {
        return [webView canZoomPageIn];
    }
}


- (BOOL)canZoomOut {
    if ([self zoomTextOnly]) {
        return [webView canMakeTextSmaller];
    } else {
        return [webView canZoomPageOut];
    }
}


- (BOOL)canActualSize {
    if ([self zoomTextOnly]) {
        return [webView canMakeTextStandardSize];
    } else {
        return [webView canResetPageZoom];
    }
}


- (IBAction)openLinkInNewTabFromMenu:(id)sender {
    NSURLRequest *req = [NSURLRequest requestWithURL:[clickElementInfo objectForKey:WebElementLinkURLKey]];
    [plugInAPI loadRequest:req destinationType:FUPlugInDestinationTypeTab];
    self.clickElementInfo = nil;
}


- (IBAction)openLinkInNewWindowFromMenu:(id)sender {
    NSURLRequest *req = [NSURLRequest requestWithURL:[clickElementInfo objectForKey:WebElementLinkURLKey]];
    [plugInAPI loadRequest:req destinationType:FUPlugInDestinationTypeWindow];
    self.clickElementInfo = nil;
}


- (IBAction)openFrameInNewWindowFromMenu:(id)sender {
    WebFrame *frame = [clickElementInfo objectForKey:WebElementFrameKey];
    NSURLRequest *req = [NSURLRequest requestWithURL:[[[frame dataSource] mainResource] URL]];
    [plugInAPI loadRequest:req destinationType:FUPlugInDestinationTypeWindow];
    self.clickElementInfo = nil;
}


- (IBAction)openImageInNewWindowFromMenu:(id)sender {
    NSURLRequest *req = [NSURLRequest requestWithURL:[clickElementInfo objectForKey:WebElementImageURLKey]];
    [plugInAPI loadRequest:req destinationType:FUPlugInDestinationTypeWindow];
    self.clickElementInfo = nil;
}


- (IBAction)searchWebFromMenu:(id)sender {
    NSString *term = [self currentSelectionFromWebView];
    if (![term length]) {
        NSBeep();
        return;
    }
    
    NSString *s = [NSString stringWithFormat:FUDefaultWebSearchFormatString(), term];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:s]];
    [plugInAPI loadRequest:req];
    self.clickElementInfo = nil;
}


- (IBAction)downloadLinkAsFromMenu:(id)sender {
    NSURL *URL = [clickElementInfo objectForKey:WebElementLinkURLKey];
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setMessage:NSLocalizedString(@"Download Linked File As...", @"")];
    NSString *filename = [[URL absoluteString] lastPathComponent];
    
    [savePanel beginSheetForDirectory:nil 
                                 file:filename 
                       modalForWindow:[self.view window] 
                        modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) 
                          contextInfo:[URL retain]]; // retained
}


#pragma mark -
#pragma mark Public

- (void)awakeFromNib {
    [locationComboBox bind:@"image" toObject:self withKeyPath:@"favicon" options:nil];
    
    NSString *path = [[NSBundle mainBundle] pathForImageResource:@"toolbar_button_home.png"];
    NSImage *img = [[[NSImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]] autorelease];
    [homeButton setImage:img];

    self.webView = [[plugInAPI newWebViewForPlugIn:self.plugIn] autorelease];
    
    [self setUpWebView];
    
    [self.view addSubview:webView];
    
    BOOL loadHomeURL = plugIn.newWindowsOpenWith;
    if (loadHomeURL) {
        self.URLString = plugIn.homeURLString;
        if ([URLString length]) {
            [self goToLocation:self];
        }
    }
    
}


- (void)didAppear {
    [self performSelector:@selector(updateNavBar) withObject:nil afterDelay:0];
}


- (void)willDisappear {
    
}


- (void)loadRequest:(NSURLRequest *)req {
    [[webView mainFrame] loadRequest:req];
}


#pragma mark -
#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)wv didStartProvisionalLoadForFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    self.URLString = [[[[frame provisionalDataSource] request] URL] absoluteString];
    self.title = NSLocalizedString(@"Loading...", @"");
}


- (void)webView:(WebView *)wv didFailProvisionalLoadWithError:(NSError *)err forFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    if (![self willRetryWithTLDAdded:wv]) {
        [self handleLoadFail:err];
    }
}


- (void)webView:(WebView *)wv didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    if (![initialURLString length]) {
        NSString *s = [[[[frame provisionalDataSource] request] URL] absoluteString];
        self.initialURLString = s;
    }
}


- (void)webView:(WebView *)wv didCommitLoadForFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    NSString *s = [webView mainFrameURL];
    self.URLString = s;
    self.favicon = [self defaultFavicon];
    
    [[self.view window] makeFirstResponder:webView];
}


- (void)webView:(WebView *)wv didReceiveTitle:(NSString *)s forFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    self.title = s;
}


- (void)webView:(WebView *)wv didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    self.favicon = image;
}


- (void)webView:(WebView *)wv didFinishLoadForFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"canReload"];
}


- (void)webView:(WebView *)wv didFailLoadWithError:(NSError *)err forFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    [self handleLoadFail:err];
}


- (void)webView:(WebView *)wv didClearWindowObject:(WebScriptObject *)wso forFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
}


#pragma mark -
#pragma mark WebPolicyDelegate

- (void)webView:(WebView *)wv decidePolicyForNavigationAction:(NSDictionary *)info request:(NSURLRequest *)req frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
    WebNavigationType navType = [[info objectForKey:WebActionNavigationTypeKey] integerValue];
    
    if (![self shouldHandleRequest:req]) {
        [listener ignore];
        return;
    }
    
    if ([WebView _canHandleRequest:req]) {
        FUBrowsaActivation *act = [FUBrowsaActivation activationFromWebActionInfo:info];
        if (act.isCommandKeyPressed) {
            [listener ignore];
            [(id)plugInAPI handleCommandClick:act request:req forWindow:[self.view window]];
        } else {
            [listener use];
        }
    } else if (WebNavigationTypePlugInRequest == navType) {
        [listener use];
    } else {
        // A file URL shouldn't fall through to here, but if it did, it would be a security risk to open it.
        if (![[req URL] isFileURL]) {
            [[NSWorkspace sharedWorkspace] openURL:[req URL]];
        }
        [listener ignore];
    }
}


- (void)webView:(WebView *)wv decidePolicyForNewWindowAction:(NSDictionary *)info request:(NSURLRequest *)req newFrameName:(NSString *)name decisionListener:(id<WebPolicyDecisionListener>)listener {
    
    if (![self shouldHandleRequest:req]) {
        [listener ignore];
        return;
    }
    
    FUBrowsaActivation *act = [FUBrowsaActivation activationFromWebActionInfo:info];
    if (act.isCommandKeyPressed) {
        [listener ignore];
        [(id)plugInAPI handleCommandClick:act request:req forWindow:[self.view window]];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:kFUTargetedClicksCreateTabsKey]) {
        [plugInAPI loadRequest:req destinationType:FUPlugInDestinationTypeTab inForeground:YES];
    } else {
        // no support for finding existing frames for name for now. allow a new window to be created
        [listener use];
    }
}


- (void)webView:(WebView *)wv decidePolicyForMIMEType:(NSString *)type request:(NSURLRequest *)req frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
    id response = [[frame provisionalDataSource] response];
    
    if (response && [response respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *headers = [response allHeaderFields];
        
        NSString *contentDisposition = [[headers objectForKey:@"Content-Disposition"] lowercaseString];
        if (contentDisposition && NSNotFound != [contentDisposition rangeOfString:@"attachment"].location) {
            if (![[[req URL] absoluteString] hasSuffix:@".user.js"]) { // don't download userscripts
                [listener download];
                return;
            }
        }
        
        NSString *contentType = [[headers objectForKey:@"Content-Type"] lowercaseString];
        if (contentType && NSNotFound != [contentType rangeOfString:@"application/octet-stream"].location) {
            [listener download];
            return;
        }
    }
    
    if ([[req URL] isFileURL]) {
        BOOL isDir = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[[req URL] path] isDirectory:&isDir];
        
        if (isDir) {
            [listener ignore];
        } else if ([WebView canShowMIMEType:type]) {
            [listener use];
        } else{
            [listener ignore];
        }
    } else if ([WebView canShowMIMEType:type]) {
        [listener use];
    } else {
        [listener download];
    }
}


- (void)webView:(WebView *)sender unableToImplementPolicyWithError:(NSError *)error frame:(WebFrame *)frame {
    NSLog(@"called unableToImplementPolicyWithError:%@ inFrame:%@", error, frame);
}


#pragma mark -
#pragma mark WebProgressNotifications

- (void)webViewProgressStarted:(NSNotification *)n {
    [self clearProgress];
    self.statusText = NSLocalizedString(@"Loading...", @"");
}


- (void)webViewProgressEstimateChanged:(NSNotification *)n {
    NSString *s = nil;
    if ([URLString length]) {
        s = [NSString stringWithFormat:NSLocalizedString(@"Loading \"%@\"", @""), URLString];
    } else {
        s = NSLocalizedString(@"Loading...", @"");
    }
    [plugInAPI showStatusText:s];
    [self displayEstimatedProgress];
}


- (void)webViewProgressFinished:(NSNotification *)n {
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"isProcessing"];
    [plugInAPI showStatusText:@""];
    [self clearProgressInFuture];
}


#pragma mark -
#pragma mark NSControl Text

- (void)controlTextDidBeginEditing:(NSNotification *)n {
    NSControl *control = [n object];
    
    if (control == locationComboBox) {
        // TODO ? use binding instead?
        [locationComboBox showDefaultIcon];
    }
}


- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    if (control == locationComboBox) {
        [plugInAPI resetMatchingRecentURLs];
        displayingMatchingRecentURLs = YES;
        return YES;
    } else {
        return YES;
    }
}


- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    if (control == locationComboBox) {
        [locationComboBox hidePopUp];
        displayingMatchingRecentURLs = NO;
        return YES;
    } else {
        return YES;
    }
}


#pragma mark -
#pragma mark NSComboBoxDataSource

- (void)comboBoxWillDismiss:(NSNotification *)n {
    if (locationComboBox == [n object]) {
        NSInteger i = [locationComboBox indexOfSelectedItem];
        NSInteger c = [locationComboBox numberOfItems];
        
        // last item (clear url menu) was clicked. clear recentURLs
        if (c && i == c - 1) {
            if (![[NSApp currentEvent] isEscKeyPressed]) {
                NSString *s = [locationComboBox stringValue];
                [locationComboBox deselectItemAtIndex:i];
                
                [plugInAPI resetRecentURLs];
                [plugInAPI resetMatchingRecentURLs];
                
                [locationComboBox reloadData];
                [locationComboBox setStringValue:s];
            }
        }
    }
}


- (id)comboBox:(NSComboBox *)cb objectValueForItemAtIndex:(NSInteger)i {
    if (locationComboBox == cb) {
        NSArray *URLs = displayingMatchingRecentURLs ? [self matchingRecentURLs] : [self recentURLs];
        
        NSInteger c = [URLs count];
        if (!c) {
            [locationComboBox hidePopUp];
        }
        if (c && i == c) {
            NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
            return [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Clear Recent URL Menu", @"") attributes:attrs] autorelease];
        } else {
            if (i < c) {
                return [URLs objectAtIndex:i];
            } else {
                return nil;
            }
        }
    } else {
        return nil;
    }
}


- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)cb {
    if (locationComboBox == cb) {
        NSArray *URLs = displayingMatchingRecentURLs ? [self matchingRecentURLs] : [self recentURLs];
        NSInteger c = [URLs count];
        if (c) {
            return c + 1;
        } else {
            [locationComboBox hidePopUp];
        }
        return c;
    } else {
        return 0;
    }
}


- (NSUInteger)comboBox:(NSComboBox *)cb indexOfItemWithStringValue:(NSString *)s {
    if (locationComboBox == cb) {
        if (displayingMatchingRecentURLs) {
            return [[self matchingRecentURLs] indexOfObject:s];
        }
        return [[self recentURLs] indexOfObject:s];
    } else {
        return 0;
    }
}


- (NSString *)comboBox:(NSComboBox *)cb completedString:(NSString *)uncompletedString {
    if (locationComboBox == cb) {
        [plugInAPI resetMatchingRecentURLs];
        
        for (NSString *s in [self recentURLs]) {
            s = [s stringByTrimmingURLSchemePrefix];
            if ([s hasPrefix:uncompletedString]) {
                [self addMatchingRecentURL:s];
            }
        }
        
        if ([[self matchingRecentURLs] count]) {
            [[locationComboBox cell] scrollItemAtIndexToVisible:0];
            [locationComboBox showPopUpWithItemCount:[[self matchingRecentURLs] count]];
            return [[self matchingRecentURLs] objectAtIndex:0];
        }
        return nil;
    } else {
        return nil;
    }
}


// prevent suggestions in locationcombobox on <esc> key
- (NSArray *)control:(NSControl *)control textView:(NSTextView *)tv completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)i {
    return nil;
}


#pragma mark -
#pragma mark HMBrowsaImageComboBoxDelegate

- (BOOL)hmComboBox:(HMBrowsaImageComboBox *)cb writeDataToPasteboard:(NSPasteboard *)pboard {
    if (locationComboBox == cb) {        
        NSString *s = [webView mainFrameURL];
        if (![s length]) {
            return NO;
        }
        
        NSString *t = [webView mainFrameTitle];
        if (![t length]) {
            t = [s stringByTrimmingURLSchemePrefix];        
        }
        
        FUWriteAllToPasteboard(s, t, pboard);
        
        return YES;
    } else {
        return NO;
    }
}


#pragma mark -
#pragma mark Private

- (void)setUpWebView {
    // delegates
    [webView setResourceLoadDelegate:self];
    [webView setFrameLoadDelegate:self];
    [webView setPolicyDelegate:self];
    [webView setUIDelegate:[[NSDocumentController sharedDocumentController] frontTabController]];
    
    [self updateUserAgentString];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(webViewProgressStarted:) name:WebViewProgressStartedNotification object:webView];
    [nc addObserver:self selector:@selector(webViewProgressEstimateChanged:) name:WebViewProgressEstimateChangedNotification object:webView];
    [nc addObserver:self selector:@selector(webViewProgressFinished:) name:WebViewProgressFinishedNotification object:webView];
    
    // dont listen for changes to browser user agent string
    [nc removeObserver:webView name:FUUserAgentStringDidChangeNotification object:nil];
}


- (void)updateNavBar {
    if (!hasUpdatedNavBar || FUShowNavBarAlways == plugIn.showNavBar) {
        hasUpdatedNavBar = YES;
        [self showNavBar:self];
    } else {
        [self hideNavBar:self];
    }
    [self.view setNeedsDisplay:YES];
    [navBar setNeedsDisplay:YES];
}


- (BOOL)willRetryWithTLDAdded:(WebView *)wv {
    NSURL *URL = [NSURL URLWithString:[wv mainFrameURL]];
    NSString *host = [URL host];
    
    if (NSNotFound == [host rangeOfString:@"."].location) {
        self.URLString = [NSString stringWithFormat:@"%@.com", host];
        [self goToLocation:self];
        return YES;
    } else {
        return NO;
    }
}


- (void)handleLoadFail:(NSError *)err {
    NSInteger code = [err code];
    
    // WebKitErrorPlugInWillHandleLoad 204
    if (NSURLErrorCancelled == code || WebKitErrorFrameLoadInterruptedByPolicyChange == code || 204 == code) {
        return;
    }
    
    self.lastLoadFailed = YES;
    
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"isProcessing"];
    self.title = NSLocalizedString(@"Load Failed", @"");
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LoadFailed" ofType:@"html"];
    NSString *source = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path] encoding:NSUTF8StringEncoding error:nil];
    source = [NSString stringWithFormat:source, [err localizedDescription]];
    
    NSURL *failingURL = [[[[webView mainFrame] provisionalDataSource] initialRequest] URL];
    NSString *failingURLString = [failingURL absoluteString];
    
    [[webView mainFrame] loadAlternateHTMLString:source baseURL:nil forUnreachableURL:failingURL];
    [self performSelector:@selector(setURLString:) withObject:failingURLString afterDelay:0];
    
    [plugInAPI removeRecentURL:failingURLString];
}


- (NSImage *)defaultFavicon {
    return [[WebIconDatabase sharedIconDatabase] defaultFavicon];
}


- (BOOL)shouldHandleRequest:(NSURLRequest *)req {
    return YES; //[[FUWhitelistController instance] processRequest:req];
}


- (BOOL)insertItem:(NSMenuItem *)item intoMenuItems:(NSMutableArray *)items afterItemWithTag:(NSInteger)tag {
    NSInteger i = [self indexOfItemWithTag:tag inMenuItems:items];
    if (NSNotFound == i) {
        [items addObject:item];
        return NO;
    } else {
        [items insertObject:item atIndex:i + 1];
        return YES;
    }
}


- (NSInteger)indexOfItemWithTag:(NSUInteger)tag inMenuItems:(NSArray *)items {
    NSInteger i = 0;
    for (NSMenuItem *item in items) {
        if ([item tag] == tag) return i; 
        i++;
    }
    return NSNotFound;
}


- (NSString *)currentSelectionFromWebView {
    DOMRange *r = [webView selectedDOMRange];
    return [r text];
}


- (void)savePanelDidEnd:(NSSavePanel *)panel returnCode:(NSInteger)code contextInfo:(NSURL *)URL {
    [URL autorelease]; // released
    
    if (NSFileHandlingPanelCancelButton == code) {
        return;
    }
    
    NSURLRequest *req = [NSURLRequest requestWithURL:URL];
    NSString *dirPath = [[panel directory] stringByExpandingTildeInPath];
    NSString *filename = [[panel filename] lastPathComponent];

    [plugInAPI downloadRequest:req directory:dirPath filename:filename];
}


- (BOOL)zoomTextOnly {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUZoomTextOnlyKey];
}


- (void)displayEstimatedProgress {
    locationComboBox.progress = [webView estimatedProgress];
}


- (void)clearProgressInFuture {
    [NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(clearProgress) userInfo:nil repeats:NO];
}


- (void)clearProgress {
    locationComboBox.progress = 0;
}


- (NSArray *)recentURLs {
    return [plugInAPI recentURLs];
}


- (NSArray *)matchingRecentURLs {
    return [plugInAPI matchingRecentURLs];
}


- (void)addRecentURL:(NSString *)s {
    [plugInAPI addRecentURL:s];
    [locationComboBox noteNumberOfItemsChanged];
    [locationComboBox reloadData];
}


- (void)addMatchingRecentURL:(NSString *)s {
    [plugInAPI addMatchingRecentURL:s];
    [locationComboBox noteNumberOfItemsChanged];
    [locationComboBox reloadData];
}


- (void)updateUserAgentString {
    [webView setCustomUserAgent:[(FUBrowsaPreferencesViewController *)plugIn.preferencesViewController userAgentString]];
}


- (void)browsaUserAgentStringDidChange:(NSNotification *)n {
    [self updateUserAgentString];
}

@synthesize plugIn;
@synthesize plugInAPI;
@synthesize webView;
@synthesize navBar;
@synthesize locationComboBox;
@synthesize homeButton;
@synthesize title;
@synthesize URLString;
@synthesize initialURLString;
@synthesize favicon;
@synthesize clickElementInfo;
@synthesize hoverElementInfo;
@synthesize statusText;
@synthesize lastLoadFailed;
@synthesize isProcessing;
@synthesize canReload;
@synthesize progress;
@end
