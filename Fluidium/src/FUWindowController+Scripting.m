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

@implementation FUWindowController (Scripting)

// overridden to send close events for background tabs thru the scripting architecture for recording
- (IBAction)takeTabIndexToCloseFrom:(id)sender {
    [self closeTabAtIndexScriptAction:sender];
}


- (IBAction)closeTabAtIndexScriptAction:(id)sender {
    FUTabController *tc = [self tabControllerAtIndex:[sender tag]];
    
    NSAppleEventDescriptor *someAE = [NSAppleEventDescriptor appleEventForFluidiumEventID:'cTab'];
    NSAppleEventDescriptor *tcDesc = [[tc objectSpecifier] descriptor];
    [someAE setDescriptor:tcDesc forKeyword:keyDirectObject];
    
    [someAE sendFluidiumAppleEvent];
}

@end
