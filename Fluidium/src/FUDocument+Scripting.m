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

@implementation FUDocument (Scripting)


#pragma mark -
#pragma mark NSObjectSpecifiers

- (FourCharCode)classCode {
    return 'fWin';
}


- (NSScriptObjectSpecifier *)objectSpecifier {
    NSUInteger i = [[NSApp orderedDocuments] indexOfObjectIdenticalTo:self];
    
    if (NSNotFound == i) {
        return nil;
    } else {
        return [[[NSIndexSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:[NSApp class]]
                                                         containerSpecifier:nil 
                                                                        key:@"orderedDocuments" 
                                                                      index:i] autorelease];
    }
}


#pragma mark -
#pragma mark Actions

- (IBAction)openTabScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'oTab'];}
//- (IBAction)goToLocationScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'GoTo'];}
- (IBAction)goBackScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'Back'];}
- (IBAction)goForwardScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'Fwrd'];}
- (IBAction)goHomeScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'Home'];}
- (IBAction)reloadScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'Reld'];}
- (IBAction)stopLoadingScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'Stop'];}
- (IBAction)zoomInScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'ZoIn'];}
- (IBAction)zoomOutScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'ZoOt'];}
- (IBAction)actualSizeScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'ActS'];}
- (IBAction)selectPreviousTabScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'PReV'];}
- (IBAction)selectNextTabScriptAction:(id)sender {[NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'NeXT'];}


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
    [windowController setSelectedTabIndex:i - 1];
}


#pragma mark -
#pragma mark Commands

- (id)handleOpenTabCommand:(NSCloseCommand *)cmd {
    [windowController openTab:nil];
    return nil;
}


- (id)handleCloseTabCommand:(NSCloseCommand *)cmd {
    [windowController performClose:nil];
    return nil;
}


- (id)handleLoadURLCommand:(NSScriptCommand *)cmd {
    return [[windowController selectedTabController] handleLoadURLCommand:cmd];
}


- (id)handleDoJavaScriptCommand:(NSScriptCommand *)cmd {
    return [[windowController selectedTabController] handleDoJavaScriptCommand:cmd];
}


- (id)handleCloseCommand:(NSCloseCommand *)cmd {
    [windowController performClose:nil];
    return nil;
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
    [windowController goBack:nil];
    return nil;
}
- (id)handleGoForwardCommand:(NSScriptCommand *)cmd {
    [windowController goForward:nil];
    return nil;
}
- (id)handleGoHomeCommand:(NSScriptCommand *)cmd {
    [windowController goHome:nil];
    return nil;
}
- (id)handleReloadCommand:(NSScriptCommand *)cmd {
    [windowController reload:nil];
    return nil;
}
- (id)handleStopLoadingCommand:(NSScriptCommand *)cmd {
    [windowController stopLoading:nil];
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
