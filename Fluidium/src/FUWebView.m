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

@interface FUWebView ()
- (void)updateWebPreferences;
- (void)updateUserAgent;
- (void)updateContinuousSpellChecking;
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

- (NSImage *)imageOfWebContentWithAspectRatio:(NSSize)size {
    NSBitmapImageRep *bitmap = [self bitmapOfWebContentWithAspectRatio:size];
    NSSize bitmapSize = [bitmap size];
    
    NSImage *image = [[[NSImage alloc] initWithSize:bitmapSize] autorelease];
    [image addRepresentation:bitmap];
    return image;
}


- (NSImage *)imageOfWebContent {
    return [self imageOfWebContentWithAspectRatio:[self bounds].size];
}


- (NSImage *)landscapeImageOfWebContent {
    return [self imageOfWebContentWithAspectRatio:NSMakeSize(3, 2)];
}


- (NSImage *)squareImageOfWebContent {
    return [self imageOfWebContentWithAspectRatio:NSMakeSize(1, 1)];
}


- (NSBitmapImageRep *)bitmapOfWebContentWithAspectRatio:(NSSize)size {
    NSSize fullSize = [self frame].size;
    
    // dont show vertical scrollbar in image
    if ([[[self mainFrame] frameView] _hasScrollBars]) {
        fullSize.width -= 40;
    }

    CGFloat ratio = 0;
    NSSize displaySize = NSZeroSize;
    
    if (size.width > size.height) {
        ratio = size.height / size.width;
        displaySize = NSMakeSize(fullSize.width, fullSize.width *ratio);
    } else {
        ratio = size.width / size.height;
        displaySize = NSMakeSize(fullSize.height * ratio, fullSize.height);
    }

    CGFloat x = fullSize.width / 2.0 - displaySize.width / 2.0;
    CGFloat y = 0;
    if (![self isFlipped]) {
        y = fullSize.height - displaySize.height;
    }
    
    CGRect r = CGRectMake(x, y, displaySize.width, displaySize.height);
    //NSLog(@"r: %@", NSStringFromRect(r));
    
    //[self lockFocus];
    NSBitmapImageRep *imageRep = [self bitmapImageRepForCachingDisplayInRect:r];
    [self cacheDisplayInRect:r toBitmapImageRep:imageRep];
    //[self unlockFocus];
    return imageRep;    
}


- (NSBitmapImageRep *)bitmapOfWebContent {
    return [self bitmapOfWebContentWithAspectRatio:[self bounds].size];
}


- (NSBitmapImageRep *)landscapeBitmapOfWebContent {
    return [self bitmapOfWebContentWithAspectRatio:NSMakeSize(3, 2)];
}


- (NSBitmapImageRep *)squareBitmapOfWebContent {
    return [self bitmapOfWebContentWithAspectRatio:NSMakeSize(1, 1)];
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

@end
