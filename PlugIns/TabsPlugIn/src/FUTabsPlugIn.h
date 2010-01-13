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
#import "FUPlugIn.h"

@class FUTabsPreferencesViewController;

@interface FUTabsPlugIn : NSObject <FUPlugIn> {
    id <FUPlugInAPI>plugInAPI;
    FUTabsPreferencesViewController *preferencesViewController;
    NSString *identifier;
    NSString *localizedTitle;
    NSInteger allowedViewPlacementMask;
    NSInteger preferredViewPlacementMask;
    NSString *preferredMenuItemKeyEquivalent;
    NSUInteger preferredMenuItemKeyEquivalentModifierMask;
    NSString *toolbarIconImageName;
    NSString *preferencesIconImageName;
    NSString *iconBundleClassName;
    NSMutableDictionary *defaultsDictionary;
    NSDictionary *aboutInfoDictionary;
    CGFloat preferredVerticalSplitPosition;
    CGFloat preferredHorizontalSplitPosition;
    
    NSMutableArray *viewControllers;
}

- (id)initWithPlugInAPI:(id <FUPlugInAPI>)api;

@property (nonatomic, retain, readonly) id <FUPlugInAPI>plugInAPI;
@property (nonatomic, retain) NSMutableArray *viewControllers;
@end
