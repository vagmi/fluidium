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

#import "FUPlugInWrapper.h"
#import "FUPlugIn.h"
#import "FUDocumentController.h"
#import "FUWindowController.h"
#import "FUTabController.h"
#import "FUNotifications.h"
#import "TDUberView.h"

@interface FUPlugInWrapper ()
@property (nonatomic, retain, readwrite) id <FUPlugIn>plugIn;
@property (nonatomic, copy, readwrite) NSString *viewPlacementMaskKey;
@property (nonatomic, retain) NSMutableSet *visibleWindowNumbers;
@end

@implementation FUPlugInWrapper

- (id)initWithPlugIn:(id <FUPlugIn>)aPlugIn {
    if (self = [super init]) {
        self.plugIn = aPlugIn;
        self.viewControllers = [NSMutableDictionary dictionary];
        self.visibleWindowNumbers = [NSMutableSet set];
        self.viewPlacementMaskKey = [NSString stringWithFormat:@"%@-currentViewPlacement", self.identifier];
        
        id existingValue = [[NSUserDefaults standardUserDefaults] objectForKey:self.viewPlacementMaskKey];
        if (!existingValue) {
            self.viewPlacementMask = self.preferredViewPlacementMask;
        }
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:plugIn];

    self.plugIn = nil;
    self.viewControllers = nil;
    self.visibleWindowNumbers = nil;
    self.viewPlacementMaskKey = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUPlugInWrapper %p %@>", self, plugIn.identifier];
}


- (BOOL)isVisibleInWindowNumber:(NSInteger)num {
    NSString *key = [[NSNumber numberWithInteger:num] stringValue];
    return [visibleWindowNumbers containsObject:key];
}


- (void)setVisible:(BOOL)visible inWindowNumber:(NSInteger)num {
    NSString *key = [[NSNumber numberWithInteger:num] stringValue];
    if (visible) {
        [visibleWindowNumbers addObject:key];
    } else {
        [visibleWindowNumbers removeObject:key];
    }
}


- (NSViewController *)plugInViewControllerForWindowNumber:(NSInteger)num {
    NSString *key = [[NSNumber numberWithInteger:num] stringValue];
    NSViewController *viewController = [viewControllers objectForKey:key];
    if (!viewController) {
        viewController = [[self newViewControllerForWindowNumber:num] autorelease];
    }
    
    return viewController;
}


- (void)addObserver:(id)target for:(NSString *)name object:(id)obj ifRespondsTo:(SEL)sel {
    if ([target respondsToSelector:sel]) {
        [[NSNotificationCenter defaultCenter] addObserver:target selector:sel name:name object:obj];
    }
}


- (NSViewController *)newViewControllerForWindowNumber:(NSInteger)num {
    NSViewController *vc = [plugIn newPlugInViewController];
    [viewControllers setObject:vc forKey:[[NSNumber numberWithInteger:num] stringValue]];
    
    [self addObserver:plugIn for:FUPlugInViewControllerWillAppearNotifcation object:vc ifRespondsTo:@selector(plugInViewControllerWillAppear:)];
    [self addObserver:plugIn for:FUPlugInViewControllerDidAppearNotifcation object:vc ifRespondsTo:@selector(plugInViewControllerDidAppear:)];
    [self addObserver:plugIn for:FUPlugInViewControllerWillDisappearNotifcation object:vc ifRespondsTo:@selector(plugInViewControllerWillDisappear:)];
    [self addObserver:plugIn for:FUPlugInViewControllerDidDisappearNotifcation object:vc ifRespondsTo:@selector(plugInViewControllerDidDisappear:)];

    [self addObserver:plugIn for:FUWindowControllerDidOpenNotification object:nil ifRespondsTo:@selector(windowControllerDidOpen:)];

    if (num > -1) {
        FUWindowController *wc = [[FUDocumentController instance] frontWindowController];
        NSWindow *win = [wc window];

        [self addObserver:vc for:FUWindowControllerWillCloseNotification object:wc ifRespondsTo:@selector(windowControllerWillClose:)];

        [self addObserver:vc for:FUWindowControllerDidOpenTabNotification object:wc ifRespondsTo:@selector(windowControllerDidOpenTab:)];
        [self addObserver:vc for:FUWindowControllerWillCloseTabNotification object:wc ifRespondsTo:@selector(windowControllerWillCloseTab:)];
        [self addObserver:vc for:FUWindowControllerDidChangeSelectedTabNotification object:wc ifRespondsTo:@selector(windowControllerDidChangeSelectedTab:)];
        
        [self addObserver:vc for:NSWindowDidResizeNotification object:win ifRespondsTo:@selector(windowDidResize:)];
        [self addObserver:vc for:NSWindowDidExposeNotification object:win ifRespondsTo:@selector(windowDidExpose:)];
        [self addObserver:vc for:NSWindowWillMoveNotification object:win ifRespondsTo:@selector(windowWillMove:)];
        [self addObserver:vc for:NSWindowDidMoveNotification object:win ifRespondsTo:@selector(windowDidMove:)];
        [self addObserver:vc for:NSWindowDidBecomeKeyNotification object:win ifRespondsTo:@selector(windowDidBecomeKey:)];
        [self addObserver:vc for:NSWindowDidResignKeyNotification object:win ifRespondsTo:@selector(windowDidResignKey:)];
        [self addObserver:vc for:NSWindowDidBecomeMainNotification object:win ifRespondsTo:@selector(windowDidBecomeMain:)];
        [self addObserver:vc for:NSWindowDidResignMainNotification object:win ifRespondsTo:@selector(windowDidResignMain:)];
        [self addObserver:vc for:NSWindowWillCloseNotification object:win ifRespondsTo:@selector(windowWillClose:)];
        [self addObserver:vc for:NSWindowWillMiniaturizeNotification object:win ifRespondsTo:@selector(windowWillMiniaturize:)];
        [self addObserver:vc for:NSWindowDidMiniaturizeNotification object:win ifRespondsTo:@selector(windowDidMiniaturize:)];
        [self addObserver:vc for:NSWindowDidDeminiaturizeNotification object:win ifRespondsTo:@selector(windowDidDeminiaturize:)];
        [self addObserver:vc for:NSWindowDidUpdateNotification object:win ifRespondsTo:@selector(windowDidUpdate:)];
        [self addObserver:vc for:NSWindowDidChangeScreenNotification object:win ifRespondsTo:@selector(windowDidChangeScreen:)];
        [self addObserver:vc for:NSWindowDidChangeScreenProfileNotification object:win ifRespondsTo:@selector(windowDidChangeScreenProfile:)];
        [self addObserver:vc for:NSWindowWillBeginSheetNotification object:win ifRespondsTo:@selector(windowWillBeginSheet:)];
        [self addObserver:vc for:NSWindowDidEndSheetNotification object:win ifRespondsTo:@selector(windowDidEndSheet:)];
        
        NSDrawer *drawer = [[win drawers] objectAtIndex:0];
        [self addObserver:vc for:NSDrawerWillOpenNotification object:drawer ifRespondsTo:@selector(drawerWillOpen:)];
        [self addObserver:vc for:NSDrawerDidOpenNotification object:drawer ifRespondsTo:@selector(drawerDidOpen:)];
        [self addObserver:vc for:NSDrawerWillCloseNotification object:drawer ifRespondsTo:@selector(drawerWillClose:)];
        [self addObserver:vc for:NSDrawerDidCloseNotification object:drawer ifRespondsTo:@selector(drawerDidClose:)];

        NSSplitView *sv = wc.uberView.verticalSplitView;
        [self addObserver:vc for:NSSplitViewWillResizeSubviewsNotification object:sv ifRespondsTo:@selector(splitViewWillResizeSubviews:)];
        [self addObserver:vc for:NSSplitViewDidResizeSubviewsNotification object:sv ifRespondsTo:@selector(splitViewDidResizeSubviews:)];

        sv = wc.uberView.horizontalSplitView;
        [self addObserver:vc for:NSSplitViewWillResizeSubviewsNotification object:sv ifRespondsTo:@selector(splitViewWillResizeSubviews:)];
        [self addObserver:vc for:NSSplitViewDidResizeSubviewsNotification object:sv ifRespondsTo:@selector(splitViewDidResizeSubviews:)];
    }
    
    return vc;
}


- (void)windowWillClose:(NSNotification *)n {
    NSWindow *window = [n object];
    NSString *key = [[NSNumber numberWithInteger:[window windowNumber]] stringValue];
    [self setVisible:NO inWindowNumber:[window windowNumber]];
    
    NSViewController *vc = [viewControllers objectForKey:key];
    [viewControllers removeObjectForKey:key];
    [[NSNotificationCenter defaultCenter] removeObserver:vc];
}

#pragma mark -
#pragma mark accessors

- (NSUInteger)viewPlacementMask {
    return [[NSUserDefaults standardUserDefaults] integerForKey:self.viewPlacementMaskKey];
}


- (void)setViewPlacementMask:(NSUInteger)mask {
    [[NSUserDefaults standardUserDefaults] setInteger:mask forKey:self.viewPlacementMaskKey];
}


#pragma mark -
#pragma mark accessors

- (NSViewController *)preferencesViewController {
    return [plugIn preferencesViewController];
}


- (NSString *)identifier {
    return [plugIn identifier];
}


- (NSString *)localizedTitle {
    return [plugIn localizedTitle];
}


- (NSInteger)allowedViewPlacementMask {
    return [plugIn allowedViewPlacementMask];
}


- (NSInteger)preferredViewPlacementMask {
    return [plugIn preferredViewPlacementMask];
}


- (NSString *)preferredMenuItemKeyEquivalent {
    return [plugIn preferredMenuItemKeyEquivalent];
}


- (NSUInteger)preferredMenuItemKeyEquivalentModifierMask {
    return [plugIn preferredMenuItemKeyEquivalentModifierMask];
}


- (NSString *)toolbarIconImageName {
    return [plugIn toolbarIconImageName];
}


- (NSString *)preferencesIconImageName {
    return [plugIn preferencesIconImageName];
}


- (NSDictionary *)defaultsDictionary {
    return [plugIn defaultsDictionary];
}


- (NSDictionary *)aboutInfoDictionary {
    return [plugIn aboutInfoDictionary];
}


- (CGFloat)preferredHorizontalSplitPosition {
    if ([plugIn respondsToSelector:@selector(preferredHorizontalSplitPosition)]) {
        return [plugIn preferredHorizontalSplitPosition];
    } else {
        return 220.;
    }
}


- (CGFloat)preferredVerticalSplitPosition {
    if ([plugIn respondsToSelector:@selector(preferredVerticalSplitPosition)]) {
        return [plugIn preferredVerticalSplitPosition];
    } else {
        return 220.;
    }
}


- (NSInteger)preferredToolbarButtonType {
    if ([plugIn respondsToSelector:@selector(preferredToolbarButtonType)]) {
        return [plugIn preferredVerticalSplitPosition];
    } else {
        return 0;
    }
}


@synthesize plugIn;
@synthesize viewControllers;
@synthesize viewPlacementMaskKey;
@synthesize visibleWindowNumbers;
@end
