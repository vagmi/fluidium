//
//  FUTabsPlugIn.h
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/25/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

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
