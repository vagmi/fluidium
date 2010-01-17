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

#import "FUTabsPlugIn.h"
#import "FUPlugIn.h"
#import "FUPlugInAPI.h"
#import "FUTabsViewController.h"
#import "FUTabsPreferencesViewController.h"
#import <Fluidium/FUNotifications.h>

@interface FUTabsPlugIn ()
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
@end

@implementation FUTabsPlugIn

- (id)initWithPlugInAPI:(id <FUPlugInAPI>)api {
    if (self = [super init]) {
        self.plugInAPI = api;
        self.identifier = @"com.fluidapp.TabsPlugIn";
        self.localizedTitle = NSLocalizedString(@"Tabs", @"");
        self.preferredMenuItemKeyEquivalentModifierMask = (NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask);
        self.toolbarIconImageName = NSImageNameIconViewTemplate;
        self.preferencesIconImageName = NSImageNameIconViewTemplate;
        self.allowedViewPlacementMask = (FUPlugInViewPlacementDrawer|
                                         FUPlugInViewPlacementSplitViewLeft|
                                         FUPlugInViewPlacementSplitViewRight|
                                         FUPlugInViewPlacementSplitViewTop|
                                         FUPlugInViewPlacementSplitViewBottom);
        self.preferredViewPlacementMask = FUPlugInViewPlacementSplitViewBottom;
        self.preferredMenuItemKeyEquivalent = @"a";
        
        // get defaults from disk
//        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"DefaultValues" ofType:@"plist"];
//        self.defaultsDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
        
        self.preferencesViewController = [[[FUTabsPreferencesViewController alloc] init] autorelease];
        
        self.preferredVerticalSplitPosition = 120;
        self.preferredHorizontalSplitPosition = 84;
        
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
    [[n object] viewWillAppear];
}


- (void)plugInViewControllerDidAppear:(NSNotification *)n {
    [[n object] viewDidAppear];
}


- (void)plugInViewControllerWillDisappear:(NSNotification *)n {
    [[n object] viewWillDisappear];
}


- (NSViewController *)newPlugInViewController {
    FUTabsViewController *vc = [[FUTabsViewController alloc] init];
    [viewControllers addObject:vc];
    vc.plugIn = self;
    vc.plugInAPI = plugInAPI;
    return vc;
}


- (NSDictionary *)aboutInfoDictionary {
    if (!aboutInfoDictionary) {
        NSString *credits = [[[NSAttributedString alloc] initWithString:@"" attributes:nil] autorelease];
        NSString *applicationName = [NSString stringWithFormat:@"%@ Tabs Plug-in", [plugInAPI appName]];

        NSImage  *applicationIcon = [NSImage imageNamed:self.preferencesIconImageName];
        
        NSString *version = @"1.0";
        NSString *copyright = @"Todd Ditchendorf 2010";
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
@end
