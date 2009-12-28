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

- (NSImage *)documentViewImageWithCurrentAspectRatio {
    return [self documentViewImageWithAspectRatio:[self bounds].size];
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


- (NSImage *)documentViewImageWithAspectRatio:(NSSize)aspectRatio {
    NSView *docView = [[[self mainFrame] frameView] documentView];

    NSRect webBounds = [self bounds];
    if (NSIsEmptyRect(webBounds)) {
        return nil;
    }
    
    NSRect docFrame = [docView frame];
    if (NSIsEmptyRect(docFrame)) {
        return nil;
    }
    
    if ([docView respondsToSelector:@selector(_layoutIfNeeded)]) {
        [docView _layoutIfNeeded];
    }
    
    CGFloat ratio = 0;
    NSRect imageFrame = NSZeroRect;
    if (aspectRatio.width > aspectRatio.height) {
        ratio = aspectRatio.height / aspectRatio.width;
        imageFrame = NSMakeRect(0, 0, docFrame.size.width, floor(docFrame.size.width * ratio));
    } else {
        ratio = aspectRatio.width / aspectRatio.height;
        imageFrame = NSMakeRect(0, 0, floor(docFrame.size.height * ratio), docFrame.size.width);
    }
    
    if (!documentViewBitmap || !NSEqualSizes([documentViewBitmap size], docFrame.size)) {
        NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!! had to make a new bitmap");
        self.documentViewBitmap = [docView bitmapImageRepForCachingDisplayInRect:docFrame];
    } else {
        NSLog(@"didnt have to make a new bitmap. reusing");
    }
    
    NSImage *documentViewImage = [[[NSImage alloc] initWithSize:docFrame.size] autorelease];
    [documentViewImage addRepresentation:documentViewBitmap];
    
    [docView cacheDisplayInRect:imageFrame toBitmapImageRep:documentViewBitmap];
    [docView setNeedsDisplay:YES];
    
    
    ///////
    CGImageRef cgImg = CGImageCreateWithImageInRect([documentViewBitmap CGImage], imageFrame);
    self.documentViewBitmap = [[[NSBitmapImageRep alloc] initWithCGImage:cgImg] autorelease];
    documentViewImage = [[[NSImage alloc] initWithSize:imageFrame.size] autorelease];
    [documentViewImage addRepresentation:documentViewBitmap];
    //////
    
    
    NSLog(@"docFrame: %@", NSStringFromRect(docFrame));
    NSLog(@"imageFrame: %@", NSStringFromRect(imageFrame));

    NSLog(@"bitmapSize: %@", NSStringFromSize([documentViewBitmap size]));
    NSLog(@"imageSize: %@", NSStringFromSize([documentViewImage size]));

    return documentViewImage;
}

@synthesize documentViewBitmap;
@end
