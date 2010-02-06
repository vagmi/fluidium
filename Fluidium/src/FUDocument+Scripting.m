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
#import "FUWindowController+Scripting.h"
#import "FUTabController+Scripting.h"
#import "FUWindowController.h"
#import "FUTabController.h"
#import "NSAppleEventDescriptor+FUAdditions.h"

#define DEFAULT_DELAY 1.0

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
    i = i - 1; // account for 1-based AppleScript indexing
    
    // delay the command a bit 
    FUTabController *tc = [windowController tabControllerAtIndex:i];
    [tc suspendCommand:[NSScriptCommand currentCommand]];
    [tc resumeSuspendedCommandAfterDelay:DEFAULT_DELAY];
    
    [windowController script_setSelectedTabIndex:i];
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
    [windowController script_closeWindow:nil];
    return nil;
}


- (id)handleNewTabCommand:(NSScriptCommand *)cmd {
    [windowController script_newTab:nil];
    return nil;
}


- (id)handleNewBackgroundTabCommand:(NSScriptCommand *)cmd {
    [windowController script_newBackgroundTab:nil];
    return nil;
}


- (id)handleCloseTabCommand:(NSScriptCommand *)cmd {
    [windowController script_closeTab:nil];
    return nil;
}


- (id)handleLoadURLCommand:(NSScriptCommand *)cmd {
    // don't call -[FUBaseScriptCommand targetTabController] here as it will route around the shortcut handling mechanism if there's no explicit tabController arg
    FUTabController *tc = [[cmd evaluatedArguments] objectForKey:@"tabController"];
    if (tc) {
        return [tc handleLoadURLCommand:cmd];
    }
    tc = [windowController selectedTabController];
    [tc suspendExecutionUntilProgressFinishedWithCommand:cmd];
    
    // dont send this straight to the tabController. that would circumvent the shortcut handling mechanism
    // which only works from the locationCombox. should we change that? for now, i say no.
    NSString *s = [cmd directParameter];
    [windowController.locationComboBox setStringValue:s];
    [windowController script_goToLocation:nil];
    return nil;
}


- (id)handleDoJavaScriptCommand:(NSScriptCommand *)cmd {
    return [[windowController selectedTabController] handleDoJavaScriptCommand:cmd];
}


- (id)handleSelectPreviousTabCommand:(NSScriptCommand *)cmd {
    [windowController script_selectPreviousTab:nil];
    return nil;
}


- (id)handleSelectNextTabCommand:(NSScriptCommand *)cmd {
    [windowController script_selectNextTab:nil];
    return nil;
}


- (id)handleGoToLocationCommand:(NSScriptCommand *)cmd {
    [windowController script_goToLocation:nil];
    return nil;
}


- (id)handleGoBackCommand:(NSScriptCommand *)cmd {
    [windowController script_webGoBack:nil];
    return nil;
}


- (id)handleGoForwardCommand:(NSScriptCommand *)cmd {
    [windowController script_webGoForward:nil];
    return nil;
}


- (id)handleReloadCommand:(NSScriptCommand *)cmd {
    [windowController script_webReload:nil];
    return nil;
}


- (id)handleStopLoadingCommand:(NSScriptCommand *)cmd {
    [windowController script_webStopLoading:nil];
    return nil;
}


- (id)handleGoHomeCommand:(NSScriptCommand *)cmd {
    [windowController script_webGoHome:nil];
    return nil;
}


- (id)handleZoomInCommand:(NSScriptCommand *)cmd {
    [windowController script_zoomIn:nil];
    return nil;
}


- (id)handleZoomOutCommand:(NSScriptCommand *)cmd {
    [windowController script_zoomOut:nil];
    return nil;
}


- (id)handleActualSizeCommand:(NSScriptCommand *)cmd {
    [windowController script_actualSize:nil];
    return nil;
}

@end
