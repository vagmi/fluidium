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

#import "FUPlugIn.h"
#import "FUWindow.h"
#import "FUWindowController.h"
#import "FUDocumentController.h"

@implementation FUPlugIn

- (id)initWithPlugInAPI:(id <FUPlugInAPI>)api {
    if (self = [super init]) {
        self.preferredHorizontalSplitPosition = 220;
        self.preferredVerticalSplitPosition = 220;
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.preferencesViewController = nil;
    self.identifier = nil;
    self.localizedTitle = nil;
    self.preferredMenuItemKeyEquivalent = nil;
    self.toolbarIconImageName = nil;
    self.preferencesIconImageName = nil;
    self.defaultsDictionary = nil;
    self.aboutInfoDictionary = nil;
    [super dealloc];
}


- (NSViewController *)newPlugInViewController {
    NSAssert2(0, @"-[FUPlugIn %s] is abstract and must be overridden in %@", _cmd, [self className]);
    return nil;
}


- (FUWindowController *)windowControllerForViewController:(NSViewController *)vc {
    NSWindow *win = [vc.view window];
    if ([win isMemberOfClass:[FUWindow class]]) {
        return [win windowController];
    } else {
        return [[FUDocumentController instance] frontWindowController];
    }
}

@synthesize preferencesViewController;
@synthesize identifier;
@synthesize localizedTitle;
@synthesize allowedViewPlacement;
@synthesize preferredViewPlacement;
@synthesize preferredMenuItemKeyEquivalent;
@synthesize preferredMenuItemKeyEquivalentModifierFlags;
@synthesize toolbarIconImageName;
@synthesize preferencesIconImageName;
@synthesize defaultsDictionary;
@synthesize aboutInfoDictionary;
@synthesize preferredVerticalSplitPosition;
@synthesize preferredHorizontalSplitPosition;
@synthesize sortOrder;
@end
