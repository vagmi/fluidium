//  Copyright 2010 Todd Ditchendorf
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

#import "FUDocument+Scripting.h"
#import "FUTabController+Scripting.h"
#import "FUWindowController.h"
#import "FUTabController.h"
#import "NSAppleEventDescriptor+FUAdditions.h"

@interface FUWindowController ()
- (void)closeWindow;
- (void)script_setSelectedTabIndex:(NSInteger)i;
@end

@implementation FUDocument (Scripting)

#pragma mark -
#pragma mark NSObjectSpecifiers

- (FourCharCode)classCode {
    return 'fDoc';
}


- (NSScriptObjectSpecifier *)objectSpecifier {
    NSUInteger i = [[NSApp orderedDocuments] indexOfObject:self];
    
    if (NSNotFound == i) {
        return nil;
    } else {
        NSScriptClassDescription *cls = [NSScriptClassDescription classDescriptionForClass:[NSApp class]];
        return [[[NSIndexSpecifier alloc] initWithContainerClassDescription:cls containerSpecifier:nil key:@"orderedDocuments" index:i] autorelease];
    }
}


#pragma mark -
#pragma mark Properties

- (NSArray *)orderedTabControllers {
    NSTabView *tabView = [windowController tabView];
    NSMutableArray *tabs = [NSMutableArray arrayWithCapacity:[tabView numberOfTabViewItems]];
    for (NSTabViewItem *tabItem in [tabView tabViewItems]) {
        [tabs addObject:[tabItem identifier]];
    }
    return [[tabs copy] autorelease];
}


- (NSUInteger)selectedTabIndex {
    return [windowController selectedTabIndex] + 1;
}


- (void)setSelectedTabIndex:(NSUInteger)i {
    [windowController script_setSelectedTabIndex:i - 1];
//    [windowController setSelectedTabIndex:i - 1];
}


- (FUTabController *)selectedTabController {
    return [windowController selectedTabController];
}


- (void)setSelectedTabController:(FUTabController *)tc {
    [windowController selectTabController:tc];
}


#pragma mark -
#pragma mark Commands

- (id)handleCloseCommand:(NSCloseCommand *)cmd {
    [windowController closeWindow:nil];
    return nil;
}


- (id)handleNewTabCommand:(NSScriptCommand *)cmd {
    [windowController newTab:nil];
    return nil;
}


- (id)handleCloseTabCommand:(NSScriptCommand *)cmd {
    [windowController closeTab:nil];
    return nil;
}


- (id)handleLoadURLCommand:(NSScriptCommand *)cmd {
    return [[windowController selectedTabController] handleLoadURLCommand:cmd];
}


- (id)handleDoJavaScriptCommand:(NSScriptCommand *)cmd {
    return [[windowController selectedTabController] handleDoJavaScriptCommand:cmd];
}


- (id)handleSelectPreviousTabCommand:(NSScriptCommand *)cmd {
    [windowController selectPreviousTab:nil];
    return nil;
}


- (id)handleSelectNextTabCommand:(NSScriptCommand *)cmd {
    [windowController selectNextTab:nil];
    return nil;
}


- (id)handleGoToLocationCommand:(NSScriptCommand *)cmd {
    [windowController goToLocation:nil];
    return nil;
}


- (id)handleGoBackCommand:(NSScriptCommand *)cmd {
    [windowController webGoBack:nil];
    return nil;
}


- (id)handleGoForwardCommand:(NSScriptCommand *)cmd {
    [windowController webGoForward:nil];
    return nil;
}


- (id)handleReloadCommand:(NSScriptCommand *)cmd {
    [windowController webReload:nil];
    return nil;
}


- (id)handleStopLoadingCommand:(NSScriptCommand *)cmd {
    [windowController webStopLoading:nil];
    return nil;
}


- (id)handleGoHomeCommand:(NSScriptCommand *)cmd {
    [windowController webGoHome:nil];
    return nil;
}


- (id)handleZoomInCommand:(NSScriptCommand *)cmd {
    [windowController zoomIn:nil];
    return nil;
}


- (id)handleZoomOutCommand:(NSScriptCommand *)cmd {
    [windowController zoomOut:nil];
    return nil;
}


- (id)handleActualSizeCommand:(NSScriptCommand *)cmd {
    [windowController actualSize:nil];
    return nil;
}

@end
