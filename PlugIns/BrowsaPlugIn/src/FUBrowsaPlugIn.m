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

#import "FUBrowsaPlugIn.h"
#import "FUPlugInAPI.h"
#import "FUBrowsaViewController.h"
#import "FUBrowsaPreferencesViewController.h"
#import "NSString+FUAdditions.h"
#import <WebKit/WebKit.h>

NSString *const FUBrowsaUserAgentStringDidChangeNotification = @"FUBrowsaUserAgentStringDidChangeNotification";

NSString *const kFUBrowsaHomeURLStringKey = @"FUBrowsaHomeURLString";
NSString *const kFUBrowsaNewWindowsOpenWithKey = @"FUBrowsaNewWindowsOpenWith";
NSString *const kFUBrowsaUserAgentStringKey = @"FUBrowsaUserAgentString";
NSString *const kFUBrowsaShowNavBarKey = @"FUBrowsaShowNavBar";
NSString *const kFUBrowsaSendLinksToKey = @"FUBrowsaSendLinksTo";

NSString *const FUPlugInViewPlacementMaskKey = @"FUPlugInViewPlacementMaskKey";

static NSInteger sTag = 0;

@interface FUBrowsaPlugIn ()
@property (nonatomic, readwrite, retain) id <FUPlugInAPI>plugInAPI;
@property (nonatomic, readwrite, retain) NSViewController *preferencesViewController;
@property (nonatomic, readwrite, copy) NSString *identifier;
@property (nonatomic, readwrite, copy) NSString *localizedTitle;
@property (nonatomic, readwrite) NSInteger allowedViewPlacementMask;
@property (nonatomic, readwrite) NSInteger preferredViewPlacementMask;
@property (nonatomic, readwrite, copy) NSString *preferredMenuItemKeyEquivalent;
@property (nonatomic, readwrite) NSUInteger preferredMenuItemKeyEquivalentModifierMask;
@property (nonatomic, readwrite, copy) NSString *toolbarIconImageName;
@property (nonatomic, readwrite, copy) NSString *preferencesIconImageName;
@property (nonatomic, readwrite, retain) NSMutableDictionary *defaultsDictionary;
@property (nonatomic, readwrite, retain) NSDictionary *aboutInfoDictionary;
@property (nonatomic, readwrite) CGFloat preferredVerticalSplitPosition;
@property (nonatomic, readwrite) CGFloat preferredHorizontalSplitPosition;
@property (nonatomic, readwrite) NSInteger tag;
@end

@implementation FUBrowsaPlugIn

- (id)initWithPlugInAPI:(id <FUPlugInAPI>)api {
    if (self = [super init]) {
        self.tag = sTag++;
        self.plugInAPI = api;
        self.identifier = [NSString stringWithFormat:@"com.fluidapp.BrowsaPlugIn%d", tag];
        self.localizedTitle = [self makeLocalizedTitle];
        self.preferredMenuItemKeyEquivalentModifierMask = (NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask);
        self.preferencesIconImageName = @"prefpane_icon_browsa";
        self.allowedViewPlacementMask = (FUPlugInViewPlacementDrawer|
                                         FUPlugInViewPlacementSplitViewLeft|
                                         FUPlugInViewPlacementSplitViewRight|
                                         FUPlugInViewPlacementSplitViewTop|
                                         FUPlugInViewPlacementSplitViewBottom);
        
        NSUInteger mask = 0;
        NSString *key = nil;
        switch (tag) {
            case 0:
                mask = FUPlugInViewPlacementSplitViewLeft;
                key = @"b";
                break;
            case 1:
                mask = FUPlugInViewPlacementSplitViewRight;
                key = @"c";
                break;
            case 2:
                mask = FUPlugInViewPlacementSplitViewTop;
                key = @"d";
                break;
            case 3:
                mask = FUPlugInViewPlacementSplitViewBottom;
                key = @"e";
                break;
            default:
                break;
        }
        self.preferredViewPlacementMask = mask;
        self.preferredMenuItemKeyEquivalent = key;
        
        // get defaults from disk, but be sure to store them using the 'tagged key' or else they're useless
        NSString *path = [[NSBundle bundleForClass:[FUBrowsaPlugIn class]] pathForResource:@"DefaultValues" ofType:@"plist"];
        NSDictionary *tdict = [NSDictionary dictionaryWithContentsOfFile:path];
        NSMutableDictionary *mdict = [NSMutableDictionary dictionaryWithCapacity:[tdict count]];
        for (NSString *key in tdict) {
            [mdict setObject:[tdict objectForKey:key] forKey:[self taggedKey:key]];
        }
        self.defaultsDictionary = [[mdict copy] autorelease];
        
        self.preferencesViewController = [[[FUBrowsaPreferencesViewController alloc] initWithPlugIn:self] autorelease];
        
        self.preferredVerticalSplitPosition = 340;
        self.preferredHorizontalSplitPosition = 250;
        
        self.viewControllers = [NSMutableArray array];
    }
    return self;
}


- (void)dealloc {
    self.plugInAPI = nil;
    self.identifier = nil;
    self.localizedTitle = nil;
    self.preferredMenuItemKeyEquivalent = nil;
    self.toolbarIconImageName = nil;
    self.preferencesIconImageName = nil;
    self.defaultsDictionary = nil;
    self.preferencesViewController = nil;
    self.aboutInfoDictionary = nil;
    self.viewControllers = nil;
    [super dealloc];
}


- (void)plugInViewControllerWillAppear:(NSNotification *)n {
}


- (void)plugInViewControllerDidAppear:(NSNotification *)n {
    FUBrowsaViewController *vc = [n object];
    [vc didAppear];
    
    NSUInteger mask = [[[n userInfo] objectForKey:FUPlugInViewPlacementMaskKey] unsignedIntegerValue];
    
    WebView *wv = [vc webView];
    NSWindow *win = [[vc view] window];
    [wv setHostWindow:win];
    
    if (FUPlugInViewPlacementIsSplitView(mask)) {
        [wv setFrame:[[vc view] frame]];
    }
    
    [win makeFirstResponder:wv];
}


- (void)plugInViewControllerWillDisappear:(NSNotification *)n {
    FUBrowsaViewController *vc = [n object];
    [vc willDisappear];
}


- (NSViewController *)newPlugInViewController {
    FUBrowsaViewController *vc = [[FUBrowsaViewController alloc] init];
    [viewControllers addObject:vc];
    vc.plugInAPI = plugInAPI;
    vc.plugIn = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:vc 
                                             selector:@selector(browsaUserAgentStringDidChange:) 
                                                 name:[self taggedKey:FUBrowsaUserAgentStringDidChangeNotification]
                                               object:nil];
    return vc;
}


- (NSDictionary *)aboutInfoDictionary {
    if (!aboutInfoDictionary) {
        NSString *credits = [[[NSAttributedString alloc] initWithString:@"" attributes:nil] autorelease];
        NSString *applicationName = @"Fluidium Browsa Plug-in";
        NSImage  *applicationIcon = [NSImage imageNamed:self.preferencesIconImageName];
        NSString *version = @"1.0";
        NSString *copyright = @"Todd Ditchendorf 2009";
        NSString *applicationVersion = @"1.0";
        
        self.aboutInfoDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    credits, @"Credits",
                                    applicationName, @"ApplicationName",
                                    applicationIcon, @"ApplicationIcon",
                                    version, @"Version",
                                    copyright, @"Copyright",
                                    applicationVersion, @"ApplicationVersion",
                                    nil];
    }
    return aboutInfoDictionary;
}


- (NSString *)taggedKey:(NSString *)inKey {
    return [NSString stringWithFormat:@"%@%d", inKey, tag];
}


- (NSString *)makeLocalizedTitle {
    NSString *result = @"Browsa";
    
    NSString *s = self.homeURLString;
    if ([s length]) {
        NSURL *homeURL = [NSURL URLWithString:s];
        NSString *host = nil;
        NSString *path = nil;
        if (homeURL) {
            host = [homeURL host];
        }
        if ([host length]) {
            path = [homeURL path];
        } else {
            NSArray *comps = [s componentsSeparatedByString:@"/"];
            if ([comps count]) {
                host = [comps objectAtIndex:0];
                if ([comps count] > 1) {
                    path = [s substringFromIndex:[s rangeOfString:@"/"].location];
                }
            }
        }
        
        if ([host hasSuffix:@"twitter.com"]) {
            result = @"Twitter";
        } else if ([host hasSuffix:@"digg.com"]) {
            result = @"Digg";
        } else if ([host hasSuffix:@"hahlo.com"]) {
            result = @"Hahlo";
        } else if ([host hasSuffix:@"socialthing.com"]) {
            result = @"Socialthing";
        } else if ([host hasSuffix:@"reader.google.com"] || ([host hasSuffix:@"google.com"] && [path hasPrefix:@"/reader"])) {
            result = @"Reader";
        } else if ([host hasSuffix:@"mail.google.com"] || ([host hasSuffix:@"google.com"] && [path hasPrefix:@"/mail"])) {
            result = @"Gmail";
        } else if ([host hasSuffix:@"google.com"] && [path hasPrefix:@"/tasks"]) {
            result = @"Tasks";
        } else if ([host hasSuffix:@"google.com"]) {
            result = @"Google";
        } else if ([host hasSuffix:@"friendfeed.com"]) {
            result = @"FriendFeed";
        } else if ([host hasSuffix:@"flickr.com"]) {
            result = @"Flickr";
        } else if ([host hasSuffix:@"brightkite.com"] || [host hasSuffix:@"bkite.com"]) {
            result = @"Brightkite";
        } else {
            NSInteger loc = [host rangeOfString:@"." options:NSBackwardsSearch].location;
            if (NSNotFound != loc && loc > 0) {
                result = [[host substringToIndex:loc] capitalizedString];
            }
        }
    }
    
    return result;
}


#pragma mark - 
#pragma mark Public

- (void)postBrowsaUserAgentStringDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:[self taggedKey:FUBrowsaUserAgentStringDidChangeNotification] object:nil];
}


#pragma mark - 
#pragma mark Properties

- (NSString *)toolbarIconImageName {
    if (!toolbarIconImageName) {
        NSString *name = @"browsa";
        
        NSString *URLString = self.homeURLString;
        if ([URLString length]) {
            
            URLString = [URLString stringByEnsuringURLSchemePrefix];
            NSURL *homeURL = [NSURL URLWithString:URLString];
            
            NSString *host = [homeURL host];
            if ([host hasSuffix:@"twitter.com"]) {
                name = @"twitter";
            } else if ([host hasSuffix:@"digg.com"]) {
                name = @"digg";
            } else if ([host hasSuffix:@"hahlo.com"]) {
                name = @"hahlo";
            } else if ([host hasSuffix:@"socialthing.com"]) {
                name = @"socialthing";
            } else if ([host hasSuffix:@"reader.google.com"] || ([host hasSuffix:@"google.com"] && [[homeURL path] hasPrefix:@"/reader"])) {
                name = @"greader";
            } else if ([host hasSuffix:@"friendfeed.com"]) {
                name = @"friendfeed";
            } else if ([host hasSuffix:@"flickr.com"]) {
                name = @"flickr";
            } else if ([host hasSuffix:@"brightkite.com"] || [host hasSuffix:@"btkite.com"]) {
                name = @"brightkite";
            }
            
        }
        self.toolbarIconImageName = [NSString stringWithFormat:@"toolbar_button_%@", name];
    }
    return toolbarIconImageName;
}


- (NSString *)homeURLString {
    return [[[NSUserDefaults standardUserDefaults] stringForKey:[self taggedKey:kFUBrowsaHomeURLStringKey]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}


- (void)setHomeURLString:(NSString *)inString {
    NSString *key = [self taggedKey:kFUBrowsaHomeURLStringKey];
    [[NSUserDefaults standardUserDefaults] setObject:[[inString copy] autorelease] forKey:key];
}


- (NSInteger)newWindowsOpenWith {
    return [[NSUserDefaults standardUserDefaults] integerForKey:[self taggedKey:kFUBrowsaNewWindowsOpenWithKey]];
}


- (void)setNewWindowsOpenWith:(NSInteger)i {
    NSString *key = [self taggedKey:kFUBrowsaNewWindowsOpenWithKey];
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:key];
}


- (NSString *)userAgentString {
    return [[NSUserDefaults standardUserDefaults] stringForKey:[self taggedKey:kFUBrowsaUserAgentStringKey]];
}


- (void)setUserAgentString:(NSString *)inString {
    NSString *key = [self taggedKey:kFUBrowsaUserAgentStringKey];
    if (inString == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:[[inString copy] autorelease] forKey:key];
    }
}


- (NSInteger)showNavBar {
    return [[NSUserDefaults standardUserDefaults] integerForKey:[self taggedKey:kFUBrowsaShowNavBarKey]];
}


- (void)setShowNavBar:(NSInteger)i {
    NSString *key = [self taggedKey:kFUBrowsaShowNavBarKey];
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:key];
}


- (NSInteger)sendLinksTo {
    return [[NSUserDefaults standardUserDefaults] integerForKey:[self taggedKey:kFUBrowsaSendLinksToKey]];
}


- (void)setSendLinksTo:(NSInteger)i {
    NSString *key = [self taggedKey:kFUBrowsaSendLinksToKey];
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:key];
}

@synthesize plugInAPI;
@synthesize preferencesViewController;
@synthesize identifier;
@synthesize localizedTitle;
@synthesize allowedViewPlacementMask;
@synthesize preferredViewPlacementMask;
@synthesize preferredMenuItemKeyEquivalent;
@synthesize preferredMenuItemKeyEquivalentModifierMask;
@synthesize toolbarIconImageName;
@synthesize preferencesIconImageName;
@synthesize defaultsDictionary;
@synthesize aboutInfoDictionary;
@synthesize preferredVerticalSplitPosition;
@synthesize preferredHorizontalSplitPosition;
@synthesize viewControllers;
@synthesize tag;
@end
