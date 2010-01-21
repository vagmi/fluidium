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

#import "FUDocumentController+Scripting.h"
#import "FUDocument+Scripting.h"
#import "FUWindowController.h"
#import "FUWindowController+Scripting.h"
#import "FUTabController.h"
#import "NSAppleEventDescriptor+FUAdditions.h"
#import <objc/runtime.h>

@implementation FUDocumentController (Scripting)

+ (void)initialize {
    if ([FUDocumentController class] == self) {
        
        Method old = class_getInstanceMethod(self, @selector(newDocument:));
        Method new = class_getInstanceMethod(self, @selector(script_newDocument:));
        method_exchangeImplementations(old, new);
        
        old = class_getInstanceMethod(self, @selector(newTab:));
        new = class_getInstanceMethod(self, @selector(script_newTab:));
        method_exchangeImplementations(old, new);

        old = class_getInstanceMethod(self, @selector(closeTab:));
        new = class_getInstanceMethod(self, @selector(script_closeTab:));
        method_exchangeImplementations(old, new);
    }
}

    
#pragma mark -
#pragma mark Actions

- (IBAction)script_newDocument:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'nDoc'];
}


- (IBAction)script_newTab:(id)sender {
    [NSAppleEventDescriptor sendVerbFirstEventWithFluidiumEventID:'nTab'];
}


- (IBAction)script_closeTab:(id)sender {
    [NSApp sendAction:@selector(closeTab:) to:nil from:sender];
}

@end
