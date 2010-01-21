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

#import "FUWindowController+Scripting.h"
#import "FUTabController.h"
#import "NSAppleEventDescriptor+FUAdditions.h"
#import <objc/runtime.h>

@implementation FUWindowController (Scripting)

+ (void)initialize {
    if ([FUWindowController class] == self) {
        
        Method old = class_getInstanceMethod(self, @selector(closeWindow:));
        Method new = class_getInstanceMethod(self, @selector(script_closeWindow:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(newTab:));
        new = class_getInstanceMethod(self, @selector(script_newTab:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(closeTab:));
        new = class_getInstanceMethod(self, @selector(script_closeTab:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(webGoBack:));
        new = class_getInstanceMethod(self, @selector(script_webGoBack:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(webGoForward:));
        new = class_getInstanceMethod(self, @selector(script_webGoForward:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(webReload:));
        new = class_getInstanceMethod(self, @selector(script_webReload:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(webStopLoading:));
        new = class_getInstanceMethod(self, @selector(script_webStopLoading:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(webGoHome:));
        new = class_getInstanceMethod(self, @selector(script_webGoHome:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(zoomIn:));
        new = class_getInstanceMethod(self, @selector(script_zoomIn:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(zoomOut:));
        new = class_getInstanceMethod(self, @selector(script_zoomOut:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(actualSize:));
        new = class_getInstanceMethod(self, @selector(script_actualSize:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(selectPreviousTab:));
        new = class_getInstanceMethod(self, @selector(script_selectPreviousTab:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(selectNextTab:));
        new = class_getInstanceMethod(self, @selector(script_selectNextTab:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(takeTabIndexToCloseFrom:));
        new = class_getInstanceMethod(self, @selector(script_takeTabIndexToCloseFrom:));
        method_exchangeImplementations(old, new);
    }
}

#pragma mark -
#pragma mark Script Actions

- (IBAction)script_closeWindow:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'cDoc'];
}
- (IBAction)script_newTab:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'oTab'];
}
- (IBAction)script_closeTab:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'cTab'];
}
- (IBAction)script_webGoBack:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'Back'];
}
- (IBAction)script_webGoForward:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'Fwrd'];
}
- (IBAction)script_webReload:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'Reld'];
}
- (IBAction)script_webStopLoading:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'Stop'];
}
- (IBAction)script_webGoHome:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'Home'];
}
- (IBAction)script_zoomIn:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'ZoIn'];
}
- (IBAction)script_zoomOut:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'ZoOt'];
}
- (IBAction)script_actualSize:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'ActS'];
}
- (IBAction)script_selectPreviousTab:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'PReV'];
}
- (IBAction)script_selectNextTab:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'NeXT'];
}

- (IBAction)script_takeTabIndexToCloseFrom:(id)sender {
    FUTabController *tc = [self tabControllerAtIndex:[sender tag]];
    
    NSAppleEventDescriptor *someAE = [NSAppleEventDescriptor appleEventForClass:'core' eventID:'clos'];
    NSAppleEventDescriptor *tcDesc = [[tc objectSpecifier] descriptor];
    [someAE setDescriptor:tcDesc forKeyword:keyDirectObject];
    
    [someAE sendFluidiumAppleEvent];
}

@end
