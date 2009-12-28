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

#import "FUWebView.h"
#import "FUApplication.h"
#import "FUUserDefaults.h"
#import "FUWebPreferences.h"
#import "FUDownloadWindowController.h"
#import "FUUserAgentWindowController.h"
#import "FUNotifications.h"
#import "WebFrameViewPrivate.h"

#define VERTICAL_SCROLL_WIDTH 40

@interface NSObject ()
- (void)_layoutIfNeeded;
@end

@interface FUWebView ()
- (void)updateWebPreferences;
- (void)updateUserAgent;
- (void)updateContinuousSpellChecking;

- (void)updateWebViewImageWithAspectRatio:(NSSize)size;
- (void)updateDocumentViewImageWithAspectRatio:(NSSize)size;

@property (nonatomic, retain) NSImage *webViewImage;
@property (nonatomic, retain) NSImage *documentViewImage;
@property (nonatomic, retain) NSBitmapImageRep *webViewBitmap;
@property (nonatomic, retain) NSBitmapImageRep *documentViewBitmap;
@end

@implementation FUWebView

- (id)initWithFrame:(NSRect)frame frameName:(NSString *)frameName groupName:(NSString *)groupName {
    if (self = [super initWithFrame:frame frameName:frameName groupName:groupName]) {
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [self setShouldCloseWithWindow:YES];
        [self setMaintainsBackForwardList:YES];
        [self setDrawsBackground:YES];
        
        [self setDownloadDelegate:[FUDownloadWindowController instance]];

        [self updateWebPreferences];
        [self updateUserAgent];
        [self updateContinuousSpellChecking];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(webPreferencesDidChange:) name:FUWebPreferencesDidChangeNotification object:[FUWebPreferences instance]];
        [nc addObserver:self selector:@selector(userAgentStringDidChange:) name:FUUserAgentStringDidChangeNotification object:nil];
        [nc addObserver:self selector:@selector(continuousSpellCheckingDidChange:) name:FUContinuousSpellCheckingDidChangeNotification object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.webViewImage = nil;
    self.documentViewImage = nil;
    self.webViewBitmap = nil;
    self.documentViewBitmap = nil;

    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUWebView %p %@>", self, [self mainFrameURL]];
}


- (NSString *)applicationNameForUserAgent {
    return [[FUApplication instance] appName];
}


#pragma mark -
#pragma mark Actions

- (IBAction)toggleContinuousSpellChecking:(id)sender {
    BOOL enabled = [[FUUserDefaults instance] continuousSpellCheckingEnabled];
    [[FUUserDefaults instance] setContinuousSpellCheckingEnabled:!enabled];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FUContinuousSpellCheckingDidChangeNotification object:self];
}


#pragma mark -
#pragma mark Notifications

- (void)webPreferencesDidChange:(NSNotification *)n {
    [self updateWebPreferences];
    [self reload:self];
}


- (void)userAgentStringDidChange:(NSNotification *)n {
    [self updateUserAgent];
}


- (void)continuousSpellCheckingDidChange:(NSNotification *)n {
    [self updateContinuousSpellChecking];
}


#pragma mark -
#pragma mark Public

- (NSImage *)webViewImageWithAspectRatio:(NSSize)size {
//    [self updateWebViewImageWithAspectRatio:size];
    [self updateDocumentViewImageWithAspectRatio:[self bounds].size];
    return documentViewImage;
}


- (NSImage *)webViewImageWithCurrentAspectRatio {
    return [self webViewImageWithAspectRatio:[self bounds].size];
}


#pragma mark -
#pragma mark Private

- (void)updateWebPreferences {
    [self setPreferences:[FUWebPreferences instance]];
}


- (void)updateUserAgent {
    [self setCustomUserAgent:[[FUUserAgentWindowController instance] userAgentString]];
}


- (void)updateContinuousSpellChecking {
    [self setContinuousSpellCheckingEnabled:[[FUUserDefaults instance] continuousSpellCheckingEnabled]];
}


- (void)updateWebViewImageWithAspectRatio:(NSSize)size {
    id frameView = [[self mainFrame] frameView];
    id docView = [frameView documentView];

    NSView *view = self;
    NSSize fullSize = [view frame].size;
    
    // dont show vertical scrollbar in image
    if ([frameView _hasScrollBars]) {
        fullSize.width -= VERTICAL_SCROLL_WIDTH;
    }
    
    if ([docView respondsToSelector:@selector(_layoutIfNeeded)]) {
        [docView _layoutIfNeeded];
    }
    
    if (NSEqualSizes(fullSize, NSZeroSize)) {
        return;
    }
    
    CGFloat ratio = 0;
    NSSize displaySize = NSZeroSize;
    
    if (size.width > size.height) {
        ratio = size.height / size.width;
        displaySize = NSMakeSize(fullSize.width, floor(fullSize.width *ratio));
    } else {
        ratio = size.width / size.height;
        displaySize = NSMakeSize(floor(fullSize.height * ratio), fullSize.height);
    }
    
    CGFloat x = floor(fullSize.width / 2.0 - displaySize.width / 2.0);
    
    CGFloat y = 0;
    if ([view isFlipped]) {
        y = 0;
    } else {
        y = fullSize.height - displaySize.height;
    }
    
    NSRect r = NSMakeRect(x, y, displaySize.width, displaySize.height);
    //NSLog(@"isFlipped: %d", [view isFlipped]);
    //NSLog(@"[bitmapImageRep size]: %@", NSStringFromSize([bitmapImageRep size]));
    NSLog(@"r: %@", NSStringFromRect(r));
    
    if (!webViewBitmap || !NSEqualSizes([webViewBitmap size], r.size)) {
        NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!! had to make a new bitmap");
        self.webViewBitmap = [view bitmapImageRepForCachingDisplayInRect:r];
    } else {
        NSLog(@"didnt have to make a new bitmap. reusing");
    }
    
    self.webViewImage = [[[NSImage alloc] initWithSize:[webViewBitmap size]] autorelease];
    [webViewImage addRepresentation:webViewBitmap];
    
    NSLog(@"webViewBitmap: %@", webViewBitmap);
    NSLog(@"webViewImage: %@", webViewImage);
    
    [view cacheDisplayInRect:r toBitmapImageRep:webViewBitmap];
    [docView setNeedsDisplay:YES];
    [view setNeedsDisplay:YES];
}


- (void)updateDocumentViewImageWithAspectRatio:(NSSize)size {
    id frameView = [[self mainFrame] frameView];
    id docView = [frameView documentView];
    
    NSView *view = docView;
    NSSize fullSize = [view frame].size;
    
    // dont show vertical scrollbar in image
    if ([frameView _hasScrollBars]) {
        fullSize.width -= VERTICAL_SCROLL_WIDTH;
    }
    
    if ([docView respondsToSelector:@selector(_layoutIfNeeded)]) {
        [docView _layoutIfNeeded];
    }
    
    if (NSEqualSizes(fullSize, NSZeroSize)) {
        return;
    }
    
    CGFloat ratio = 0;
    NSSize displaySize = NSZeroSize;
    
    if (size.width > size.height) {
        ratio = size.height / size.width;
        displaySize = NSMakeSize(fullSize.width, floor(fullSize.width *ratio));
    } else {
        ratio = size.width / size.height;
        displaySize = NSMakeSize(floor(fullSize.height * ratio), fullSize.height);
    }
    
    CGFloat x = floor(fullSize.width / 2.0 - displaySize.width / 2.0);
    
    CGFloat y = 0;
    if ([view isFlipped]) {
        y = 0;
    } else {
        y = fullSize.height - displaySize.height;
    }
    
    NSRect r = NSMakeRect(x, y, displaySize.width, displaySize.height);
    //NSLog(@"isFlipped: %d", [view isFlipped]);
    NSLog(@"r: %@", NSStringFromRect(r));
    
    if (!documentViewBitmap || !NSEqualSizes([documentViewBitmap size], r.size)) {
        NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!! had to make a new bitmap");
        self.documentViewBitmap = [view bitmapImageRepForCachingDisplayInRect:r];
    } else {
        NSLog(@"didnt have to make a new bitmap. reusing");
    }
    
    self.documentViewImage = [[[NSImage alloc] initWithSize:[documentViewBitmap size]] autorelease];
    [documentViewImage addRepresentation:documentViewBitmap];
    
    NSLog(@"documentViewBitmap: %@", documentViewBitmap);
    NSLog(@"documentViewImage: %@", documentViewImage);
    
    [view cacheDisplayInRect:r toBitmapImageRep:documentViewBitmap];
    [docView setNeedsDisplay:YES];
    [view setNeedsDisplay:YES];
}

@synthesize webViewImage;
@synthesize documentViewImage;
@synthesize webViewBitmap;
@synthesize documentViewBitmap;
@end
