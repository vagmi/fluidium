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

#import "FUApplication.h"
#import "FUUserDefaults.h"
#import "FUNotifications.h"
#import "FUDownloadWindowController.h"
#import "FUBookmarkWindowController.h"
#import "FUUserthingWindowController.h"
#import "PTHotKey.h"
#import "FUAppearancePreferences.h"
#import "FUPlugInPreferences.h"
#import "FUDocumentController.h"
#import "FUWhitelistController.h"
#import "FUUserscriptController.h"
#import "FUUserstyleController.h"
#import "FURecentURLController.h"
#import "FUHistoryController.h"
#import "FUPlugInController.h"
#import "FUDownloadWindowController.h"
#import "FUUserAgentWindowController.h"
#import "FUBookmarkController.h"
#import <OmniAppKit/OAPreferenceController.h>

#define ABOUT_ITEM_TAG 547
#define HIDE_ITEM_TAG 647
#define QUIT_MENU_TAG 747

static NSString *const kFUApplicationLastVersionStringKey = @"FUApplicationLastVersionString";

@interface FUApplication ()
- (void)readInfoPlist;
- (void)updateAppNameInMainMenu;
- (BOOL)createDirAtPathIfDoesntExist:(NSString *)path;
- (void)checkForVersionChange;
@end

@implementation FUApplication

+ (FUApplication *)instance {
    return (FUApplication *)[self sharedApplication];
}


- (id)init {
    if (self = [super init]) {
        [self readInfoPlist];
        [self setUpAppSupportDir];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:self];
        [nc addObserver:self selector:@selector(applicationWillResignActive:) name:NSApplicationWillResignActiveNotification object:self];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.appName = nil;
    self.versionString = nil;
    self.appSupportDirPath = nil;
    self.ssbSupportDirPath = nil;
    self.userscriptDirPath = nil;
    self.userscriptFilePath = nil;
    self.userstyleDirPath = nil;
    self.userstyleFilePath = nil;
    self.bookmarksFilePath = nil;
    self.downloadArchiveFilePath = nil;
    self.plugInPrivateDirPath = nil;
    self.plugInDirPath = nil;
    self.plugInSupportDirPath = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    if (isFluidSSB) {
        [self updateAppNameInMainMenu];
    }
}


#pragma mark -
#pragma mark Actions

- (IBAction)showDownloadsWindow:(id)sender {
    [[FUDownloadWindowController instance] showWindow:sender];
}


- (IBAction)showBookmarksWindow:(id)sender {
    [[FUBookmarkWindowController instance] showWindow:sender];
}


- (IBAction)showUserscriptsWindow:(id)sender {
    [[FUUserthingWindowController instance] showUserscripts:sender];
}


- (IBAction)showUserstylesWindow:(id)sender {
    [[FUUserthingWindowController instance] showUserstyles:sender];
}


- (IBAction)globalShortcutActivated:(id)sender {
    [self activateIgnoringOtherApps:YES];
}


// font panel support
- (IBAction)changeFont:(id)sender {
    NSWindow *win = [NSApp mainWindow];
    
    BOOL prefWinIsMain = [[win className] isEqualToString:@"OAPreferencesWindow"];
    BOOL viewSourceWinIsMain = NO; //[win isKindOfClass:[TDSourceCodeTextView class]];
    
    if (prefWinIsMain) {
        OAPreferenceClient *client = [[OAPreferenceController sharedPreferenceController] currentClient];
        if (client) {
            [client changeFont:sender];
        }
    } else if (viewSourceWinIsMain) {
        
    }
    
}


#pragma mark -
#pragma mark Public

- (BOOL)isFullScreen {
    return NO;
}


- (void)showPreferencePaneForIdentifier:(NSString *)s {
    [[OAPreferenceController sharedPreferenceController] showPreferencesPanel:self];
    [[OAPreferenceController sharedPreferenceController] setCurrentClientRecord:[OAPreferenceController clientRecordWithIdentifier:s]];
}


- (NSString *)defaultUserAgentString {
    return [[FUUserAgentWindowController instance] defaultUserAgentString];
}


- (NSArray *)allUserAgentStrings {
    return [[FUUserAgentWindowController instance] allUserAgentStrings];
}


- (void)readInfoPlist {
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];

    // version
    self.versionString = [infoPlist valueForKey:@"CFBundleVersion"];
    
    // appName
    NSString *name = [infoPlist valueForKey:@"FUAppName"];
    if ([name length]) {
        isFluidSSB = YES;
    } else {
        name = [infoPlist valueForKey:@"CFBundleName"];
    }
    self.appName = name;
}


- (void)updateAppNameInMainMenu {
    NSMenu *appMenu = [[[self mainMenu] itemAtIndex:0] submenu];

    if (appMenu) {        
        NSArray *items = [appMenu itemArray];
        NSMenuItem *aboutItem = [items objectAtIndex:[appMenu indexOfItemWithTag:ABOUT_ITEM_TAG]];
        [aboutItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"About %@", @""), appName]];
        NSMenuItem *hideItem = [items objectAtIndex:[appMenu indexOfItemWithTag:HIDE_ITEM_TAG]];
        [hideItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Hide %@", @""), appName]];
        NSMenuItem *quitItem = [items objectAtIndex:[appMenu indexOfItemWithTag:QUIT_MENU_TAG]];
        [quitItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), appName]];
    }

    NSMenu *helpMenu = [[[[self mainMenu] itemArray] lastObject] submenu];
    if (helpMenu) {
        NSArray *items = [helpMenu itemArray];
        NSMenuItem *helpItem = [items lastObject];
        [helpItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ Help", @""), appName]];
    }
}


- (BOOL)setUpAppSupportDir {
    NSString *dirName = isFluidSSB ? @"Fluid" : appName;
    NSArray *pathComps = [NSArray arrayWithObjects:@"~", @"Library", @"Application Support", dirName, nil];
    NSString *path = [[NSString pathWithComponents:pathComps] stringByExpandingTildeInPath];
    self.appSupportDirPath = path;
    self.plugInDirPath = [appSupportDirPath stringByAppendingPathComponent:@"PlugIns"];
    self.plugInPrivateDirPath = [[NSBundle mainBundle] builtInPlugInsPath];
    
    BOOL success = [self createDirAtPathIfDoesntExist:appSupportDirPath];
    
    if (success) {
        path = [path stringByAppendingPathComponent:@"SSB"];
        [self createDirAtPathIfDoesntExist:path];
        
        path = [path stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]];
        self.ssbSupportDirPath = path;
        [self createDirAtPathIfDoesntExist:ssbSupportDirPath];

        self.userscriptDirPath = [ssbSupportDirPath stringByAppendingPathComponent:@"Userscripts"];
        [self createDirAtPathIfDoesntExist:userscriptDirPath];
        self.userscriptFilePath = [[userscriptDirPath stringByAppendingPathComponent:@"Userscripts"] stringByAppendingPathExtension:@"plist"];
        
        self.userstyleDirPath = [ssbSupportDirPath stringByAppendingPathComponent:@"Userstyles"];
        [self createDirAtPathIfDoesntExist:userstyleDirPath];
        self.userstyleFilePath = [[userstyleDirPath stringByAppendingPathComponent:@"Userstyles"] stringByAppendingPathExtension:@"plist"];
        
        self.downloadArchiveFilePath = [ssbSupportDirPath stringByAppendingPathComponent:@"DownloadArchive"];
        self.bookmarksFilePath = [ssbSupportDirPath stringByAppendingPathComponent:@"Bookmarks"];

        self.plugInSupportDirPath = [ssbSupportDirPath stringByAppendingPathComponent:@"PlugIn Support"];
        [self createDirAtPathIfDoesntExist:plugInSupportDirPath];

        path = [appSupportDirPath stringByAppendingPathComponent:@"IconDatabase"];
        success = [self createDirAtPathIfDoesntExist:path];
        if (success) {
            // must set value for this WebKit user defaults key in the user defaults or else favicons will never be created
            [[FUUserDefaults instance] setWebIconDatabaseDirectoryDefaults:path];
        }
    }
    
    return success;
}


- (BOOL)createDirAtPathIfDoesntExist:(NSString *)path {
    BOOL exists, isDir;
    exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    BOOL success = (exists && isDir);
    
    if (!success) {
        NSError *err = nil;
        success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
        if (!success) {
            NSLog(@"Fluidium could not create dir at path: %@: %@", path, err);
        }
    }
    
    return success;
}


#pragma mark -
#pragma mark Private

- (void)checkForVersionChange {
    NSString *lastVers = [[NSUserDefaults standardUserDefaults] stringForKey:kFUApplicationLastVersionStringKey];
    if (![lastVers isEqualToString:versionString]) {
        [[NSUserDefaults standardUserDefaults] setObject:versionString forKey:kFUApplicationLastVersionStringKey];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FUApplicationVersionDidChangeNotification object:self];
    }    
}


#pragma mark -
#pragma mark Notifications

- (void)finishLaunching {
    [super finishLaunching];
    
    // instantiate singletons
    [FUWhitelistController instance];
    [FUUserstyleController instance];
    [FUBookmarkController instance];
    [FUHistoryController instance];
    [FUPlugInController instance];
    [FUUserscriptController instance];
    [FUUserstyleController instance];
    [FUUserAgentWindowController instance];

    [self checkForVersionChange];
}


- (void)applicationWillTerminate:(NSNotification *)n {
    [[FUDownloadWindowController instance] save];
    [[FUWhitelistController instance] save];
    [[FURecentURLController instance] save];
    [[FUBookmarkController instance] save];
    [[FUHistoryController instance] save];
    [[FUUserscriptController instance] save];
    [[FUUserstyleController instance] save];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)applicationWillResignActive:(NSNotification *)n {
    [[FUHistoryController instance] save];
    [[FUDocumentController instance] saveSession];
}


- (void)applicationDidLaunchWithPristinePerferences:(NSNotification *)n {
    NSString *s = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FUHomeURLString"];
    if ([s length]) {
        [[FUUserDefaults instance] setHomeURLString:s];
    }    
}

@synthesize appName;
@synthesize versionString;
@synthesize appSupportDirPath;
@synthesize ssbSupportDirPath;
@synthesize userscriptDirPath;
@synthesize userscriptFilePath;
@synthesize userstyleDirPath;
@synthesize userstyleFilePath;
@synthesize bookmarksFilePath;
@synthesize downloadArchiveFilePath;
@synthesize plugInPrivateDirPath;
@synthesize plugInDirPath;
@synthesize plugInSupportDirPath;
@end
