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

#import "FUWindowController+NSToolbarDelegate.h"
#import "FUWindowController.h"
#import "FUApplication.h"
#import "FUUserDefaults.h"
#import "FUWindowToolbar.h"
#import "FUBackForwardPopUpButton.h"
#import "FUPlugInController.h"
#import "FUPlugInWrapper.h"

static NSString *const FUBackItemIdentifier = @"FUBackItemIdentifier";
static NSString *const FUForwardItemIdentifier = @"FUForwardItemIdentifier";
static NSString *const FUReloadItemIdentifier = @"FUReloadItemIdentifier";
static NSString *const FUStopItemIdentifier = @"FUStopItemIdentifier";
static NSString *const FUHomeItemIdentifier = @"FUHomeItemIdentifier";
static NSString *const FULocationItemIdentifier = @"FULocationItemIdentifier";
static NSString *const FUTextSmallerItemIdentifier = @"FUTextSmallerItemIdentifier";
static NSString *const FUTextLargerItemIdentifier = @"FUTextLargerItemIdentifier";

@interface FUWindowController (NSToolbarDelegatePrivate)
- (NSToolbarItem *)toolbarItemForPlugInWrapper:(FUPlugInWrapper *)wrap;
- (NSToolbarItem *)buttonToolbarItemWithIdentifier:(NSString *)itemID imageNamed:(NSString *)name label:(NSString *)label target:(id)target action:(SEL)sel;
- (NSToolbarItem *)buttonToolbarItemWithIdentifier:(NSString *)itemID image:(NSImage *)img label:(NSString *)label target:(id)target action:(SEL)sel;
- (NSToolbarItem *)viewToolbarItemWithIdentifier:(NSString *)itemID view:(NSView *)view label:(NSString *)label target:(id)target action:(SEL)sel;
- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier label:(NSString *)label;
- (NSArray *)allPlugInToolbarItemIdentifiers;
@end

@implementation FUWindowController (NSToolbarDelegate)

- (void)setUpToolbar {
    FUWindowToolbar *toolbar = [[[FUWindowToolbar alloc] initWithIdentifier:@"FUWindowToolbar"] autorelease];
    [toolbar setShowsBaselineSeparator:NO];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setAutosavesConfiguration:YES];
    [[self window] setToolbar:toolbar];
    [toolbar setWindow:[self window]];
    [toolbar setVisible:[[FUUserDefaults instance] toolbarShown]];
}


#pragma mark -
#pragma mark NSToolbarDelegate

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)tb {
    NSMutableArray *a = [NSMutableArray arrayWithObjects:
                         FUBackItemIdentifier,
                         FUForwardItemIdentifier,
                         FUReloadItemIdentifier,
                         FUStopItemIdentifier,
                         FUHomeItemIdentifier, 
                         FULocationItemIdentifier,
                         nil];
    
    [a addObjectsFromArray:[self allPlugInToolbarItemIdentifiers]];
    return a;
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)tb {
    NSMutableArray *a = [NSMutableArray arrayWithObjects:
                         NSToolbarPrintItemIdentifier,
                         NSToolbarCustomizeToolbarItemIdentifier,
                         NSToolbarFlexibleSpaceItemIdentifier,
                         NSToolbarSpaceItemIdentifier,
                         NSToolbarSeparatorItemIdentifier, 
                         FUBackItemIdentifier,
                         FUForwardItemIdentifier,
                         FUTextSmallerItemIdentifier,
                         FUTextLargerItemIdentifier,
                         FUReloadItemIdentifier,
                         FUStopItemIdentifier,
                         FUHomeItemIdentifier, 
                         FULocationItemIdentifier,
                         nil];    

    [a addObjectsFromArray:[self allPlugInToolbarItemIdentifiers]];
    return a;
}


- (NSToolbarItem *)toolbar:(NSToolbar *)tb itemForItemIdentifier:(NSString *)itemID willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = nil;
    NSString *name = nil;
    BOOL isFullScreen = [[FUApplication instance] isFullScreen];

    if ([itemID isEqualToString:FUBackItemIdentifier]) {
        name = isFullScreen ? @"fullscreen_toolbar_button_back" : NSImageNameGoLeftTemplate;
        item = [self buttonToolbarItemWithIdentifier:itemID imageNamed:name label:NSLocalizedString(@"Back", @"") target:self action:@selector(goBack:)];
        [[item view] bind:@"enabled" toObject:self withKeyPath:@"selectedTabController.webView.canGoBack" options:nil];

    } else if ([itemID isEqualToString:FUForwardItemIdentifier]) {
        name = isFullScreen ? @"fullscreen_toolbar_button_fwd" : NSImageNameGoRightTemplate;
        item = [self buttonToolbarItemWithIdentifier:itemID imageNamed:name label:NSLocalizedString(@"Forward", @"") target:self action:@selector(goForward:)];
        [[item view] bind:@"enabled" toObject:self withKeyPath:@"selectedTabController.webView.canGoForward" options:nil];

    } else if ([itemID isEqualToString:FUReloadItemIdentifier]) {
        name = isFullScreen ? @"fullscreen_toolbar_button_reload" : NSImageNameRefreshTemplate;
        item = [self buttonToolbarItemWithIdentifier:itemID imageNamed:name label:NSLocalizedString(@"Reload", @"") target:self action:@selector(reload:)];
        [[item view] bind:@"enabled" toObject:self withKeyPath:@"selectedTabController.canReload" options:nil];

    } else if ([itemID isEqualToString:FUStopItemIdentifier]) {
        name = isFullScreen ? @"fullscreen_toolbar_button_stop" : NSImageNameStopProgressTemplate;
        item = [self buttonToolbarItemWithIdentifier:itemID imageNamed:name label:NSLocalizedString(@"Stop", @"") target:self action:@selector(stopLoading:)];
        [[item view] bind:@"enabled" toObject:self withKeyPath:@"selectedTabController.webView.isLoading" options:nil];

    } else if ([itemID isEqualToString:FUHomeItemIdentifier]) {
        name = isFullScreen ? @"fullscreen_toolbar_button_home" : @"toolbar_button_home";
        item = [self buttonToolbarItemWithIdentifier:itemID imageNamed:name label:NSLocalizedString(@"Home", @"") target:self action:@selector(goHome:)];

    } else if ([itemID isEqualToString:FUTextSmallerItemIdentifier]) {
        name = isFullScreen ? @"fullscreen_toolbar_button_smaller" : NSImageNameRemoveTemplate;
        item = [self buttonToolbarItemWithIdentifier:itemID imageNamed:name label:NSLocalizedString(@"Smaller", @"") target:self action:@selector(zoomOut:)];
        [[item view] bind:@"enabled" toObject:self withKeyPath:@"selectedTabController.webView.canMakeTextSmaller" options:nil];

    } else if ([itemID isEqualToString:FUTextLargerItemIdentifier]) {
        name = isFullScreen ? @"fullscreen_toolbar_button_larger" : NSImageNameAddTemplate;
        item = [self buttonToolbarItemWithIdentifier:itemID imageNamed:name label:NSLocalizedString(@"Larger", @"") target:self action:@selector(zoomIn:)];
        [[item view] bind:@"enabled" toObject:self withKeyPath:@"selectedTabController.webView.canMakeTextLarger" options:nil];

    } else if ([itemID isEqualToString:FULocationItemIdentifier]) {
        item = [self viewToolbarItemWithIdentifier:itemID view:locationSplitView label:NSLocalizedString(@"Address / Search", @"") target:self action:nil];
        [locationSplitView resizeSubviewsWithOldSize:NSMakeSize(0, 0)];

    } else {
        item = [self toolbarItemForPlugInWrapper:[[FUPlugInController instance] plugInWrapperForIdentifier:itemID]];

    } 
    
    return item;
}


#pragma mark -
#pragma mark Private

- (NSToolbarItem *)toolbarItemForPlugInWrapper:(FUPlugInWrapper *)wrap {
    if (!wrap) return nil;
    
    NSBundle *bundle = [NSBundle bundleForClass:[wrap.plugIn class]];
    NSString *path = [bundle pathForImageResource:wrap.toolbarIconImageName];
    NSImage *img = nil;
    
    if ([path length]) {
        NSURL *URL = [NSURL fileURLWithPath:path];
        img = [[[NSImage alloc] initWithContentsOfURL:URL] autorelease];
    } 
    
    if (!img) {
        img = [NSImage imageNamed:wrap.toolbarIconImageName];
    }
    
    return [self buttonToolbarItemWithIdentifier:wrap.identifier image:img label:[wrap localizedTitle] target:[FUPlugInController instance] action:@selector(plugInMenuItemAction:)];
}


- (NSToolbarItem *)buttonToolbarItemWithIdentifier:(NSString *)itemID imageNamed:(NSString *)name label:(NSString *)label target:(id)target action:(SEL)sel {
    return [self buttonToolbarItemWithIdentifier:itemID image:[NSImage imageNamed:name] label:label target:target action:sel];
}


- (NSToolbarItem *)buttonToolbarItemWithIdentifier:(NSString *)itemID image:(NSImage *)img label:(NSString *)label target:(id)target action:(SEL)sel {
    NSToolbarItem *item = [self toolbarItemWithIdentifier:itemID label:label];
    
    Class buttonClass = nil;
    if (@selector(goBack:) == sel || @selector(goForward:) == sel) {
        buttonClass = [FUBackForwardPopUpButton class];
    } else {
        buttonClass = [NSButton class];
    }
    
    NSButton *b = [[[buttonClass alloc] initWithFrame:NSMakeRect(0, 0, 28, 23)] autorelease];
    [[b cell] setRepresentedObject:itemID];
    [b setButtonType:NSMomentaryPushInButton];
    [b setTarget:target];
    [b setAction:sel];
    
    if ([[FUApplication instance] isFullScreen]) {
        [b setBordered:NO];
    } else {
        [b setBezelStyle:NSTexturedRoundedBezelStyle];
    }
    
    [b setImage:img];
    [item setView:b];
    return item;
}


- (NSToolbarItem *)viewToolbarItemWithIdentifier:(NSString *)itemID view:(NSView *)view label:(NSString *)label target:(id)target action:(SEL)sel {    
    NSToolbarItem *item = [self toolbarItemWithIdentifier:itemID label:label];
    [item setView:view];
    [item setMinSize:NSMakeSize(80, NSHeight([view frame]))];
    [item setMaxSize:NSMakeSize(NSIntegerMax, NSHeight([view frame]))];        
    return item;
}


- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier label:(NSString *)label {
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    [item setLabel:label];
    [item setPaletteLabel:label];
    return item;
}


- (NSArray *)allPlugInToolbarItemIdentifiers {
    return [[FUPlugInController instance] allPlugInIdentifiers];
}

@end
