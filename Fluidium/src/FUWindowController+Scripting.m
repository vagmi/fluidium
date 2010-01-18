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
#import "FUReloadCommand.h"
#import "NSAppleEventDescriptor+FUAdditions.h"

@interface FUWindowController (ScriptingPrivate)
- (void)sendEventWithCode:(FourCharCode)code sender:(id)sender;
@end

@implementation FUWindowController (Scripting)

- (void)sendEventWithCode:(FourCharCode)code sender:(id)sender {
    NSAppleEventDescriptor *someAE = [NSAppleEventDescriptor appleEventForFluidiumEventID:code];
    
    //NSAppleEventDescriptor *directObjDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeWildCard bytes:<#(const void *)bytes#> length:<#(NSUInteger)byteCount#>
    //[someAE setDescriptor:directObjDesc forKeyword:keyDirectObject];
    
    [someAE sendFluidiumAppleEvent];
}


- (IBAction)goToLocationScriptAction:(id)sender {
    [self sendEventWithCode:'GoTo' sender:sender];
}


- (IBAction)goBackScriptAction:(id)sender {
    [self sendEventWithCode:'Back' sender:sender];
}


- (IBAction)goForwardScriptAction:(id)sender {
    [self sendEventWithCode:'Fwrd' sender:sender];
}


- (IBAction)goHomeScriptAction:(id)sender {
    [self sendEventWithCode:'Home' sender:sender];
}


- (IBAction)reloadScriptAction:(id)sender {
    [self sendEventWithCode:'Reld' sender:sender];
}


- (IBAction)stopLoadingScriptAction:(id)sender {
    [self sendEventWithCode:'Stop' sender:sender];
}


- (IBAction)zoomInScriptAction:(id)sender {
    [self sendEventWithCode:'ZoIn' sender:sender];
}


- (IBAction)zoomOutScriptAction:(id)sender {
    [self sendEventWithCode:'ZoOt' sender:sender];
}


- (IBAction)actualSizeScriptAction:(id)sender {
    [self sendEventWithCode:'ActS' sender:sender];
}


- (IBAction)selectPreviousTabScriptAction:(id)sender {
    [self sendEventWithCode:'PReV' sender:sender];
}


- (IBAction)selectNextTabScriptAction:(id)sender {
    [self sendEventWithCode:'NeXT' sender:sender];
}


- (IBAction)addBookmarkScriptAction:(id)sender {
    [self sendEventWithCode:'Bkmk' sender:sender];
}


- (IBAction)viewSourceScriptAction:(id)sender {
    [self sendEventWithCode:'VSrc' sender:sender];
}

@end