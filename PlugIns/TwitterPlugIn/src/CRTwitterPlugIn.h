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
#import <Fluidium/FUPlugIn.h>

@class CRTwitterPlugInViewController;
@class CRTwitterPlugInPrefsViewController;

extern NSString *kCRTwitterDisplayUsernamesKey;
extern NSString *kCRTwitterAccountIDsKey;
extern NSString *kCRTwitterSelectNewTabsAndWindowsKey;

extern NSString *CRTwitterSelectedUsernameDidChangeNotification;
extern NSString *CRTwitterDisplayUsernamesDidChangeNotification;

@interface CRTwitterPlugIn : FUPlugIn {
    id <FUPlugInAPI>plugInAPI; // weakref

    CRTwitterPlugInViewController *frontViewController;
    
    NSString *selectedUsername;
}

+ (CRTwitterPlugIn *)instance;

- (void)showPrefs:(id)sender;

// prefs
- (BOOL)tabbedBrowsingEnabled;
- (BOOL)selectNewWindowsOrTabsAsCreated;

- (void)openURLString:(NSString *)s;
- (void)openURL:(NSURL *)URL;
- (void)openURLWithArgs:(NSDictionary *)args;

- (void)openURL:(NSURL *)URL inNewTabInForeground:(BOOL)inBackground;
- (void)openURL:(NSURL *)URL inNewWindowInForeground:(BOOL)inBackground;

- (void)showStatusText:(NSString *)s;

- (NSArray *)usernames;
- (NSString *)passwordFor:(NSString *)username;

- (BOOL)wasCommandKeyPressed:(NSInteger)modifierFlags;
- (BOOL)wasShiftKeyPressed:(NSInteger)modifierFlags;
- (BOOL)wasOptionKeyPressed:(NSInteger)modifierFlags;

@property (nonatomic, assign) id <FUPlugInAPI>plugInAPI; // weakref
@property (nonatomic, assign) CRTwitterPlugInViewController *frontViewController; // weakref
@property (nonatomic, copy) NSString *selectedUsername;
@end
