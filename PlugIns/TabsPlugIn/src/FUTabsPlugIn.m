//
//  FUTabsPlugIn.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/25/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "FUTabsPlugIn.h"
#import "FUNotifications.h"
#import "FUPlugIn.h"
#import "FUPlugInAPI.h"
#import "FUTabsViewController.h"
#import "FUTabsPreferencesViewController.h"

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
        self.preferencesIconImageName = NSImageNameIconViewTemplate;
        self.allowedViewPlacementMask = (FUPlugInViewPlacementDrawer|
                                         FUPlugInViewPlacementSplitViewLeft|
                                         FUPlugInViewPlacementSplitViewRight|
                                         FUPlugInViewPlacementSplitViewTop|
                                         FUPlugInViewPlacementSplitViewBottom);
        self.preferredViewPlacementMask = FUPlugInViewPlacementSplitViewBottom;
        self.preferredMenuItemKeyEquivalent = @"t";
        
        // get defaults from disk
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"DefaultValues" ofType:@"plist"];
        self.defaultsDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
        
        self.preferencesViewController = [[[FUTabsPreferencesViewController alloc] init] autorelease];
        
        self.preferredVerticalSplitPosition = 340;
        self.preferredHorizontalSplitPosition = 120;
        
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
    FUTabsViewController *vc = [n object];
    [vc viewDidAppear];
}


- (void)plugInViewControllerWillDisappear:(NSNotification *)n {
    FUTabsViewController *vc = [n object];
    [vc viewWillDisappear];
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
        NSString *applicationName = @"Fluidium Tabs Plug-in";
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
