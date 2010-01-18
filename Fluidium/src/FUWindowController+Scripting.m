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
#import "FUScriptUtils.h"

@interface FUWindowController (ScriptingPrivate)
- (void)sendEventWithCode:(FourCharCode)code;
@end

@implementation FUWindowController (Scripting)

- (void)sendEventWithCode:(FourCharCode)code {
    OSErr err = noErr;
    AEAddressDesc addressDesc = FUCreateTargetProcessDesc(&err);
    if (noErr != noErr) {
        goto done;
    }
    
    err = noErr;
    AppleEvent someAE;
    err = AECreateAppleEvent('FuSS', code, &addressDesc, kAutoGenerateReturnID, kAnyTransactionID, &someAE);
    if (noErr != err) {
        goto done;
    }
    
    err = noErr; 
    err = AESendMessage(&someAE, NULL, kAENoReply|kAENeverInteract, kAEDefaultTimeout);
    
done:
    AEDisposeDesc(&addressDesc);
    AEDisposeDesc(&someAE);
}


- (IBAction)goBackScriptAction:(id)sender {
    [self sendEventWithCode:'Back'];
}


- (IBAction)goForwardScriptAction:(id)sender {
    [self sendEventWithCode:'Fwrd'];
}


- (IBAction)goHomeScriptAction:(id)sender {
    [self sendEventWithCode:'Home'];
}


- (IBAction)reloadScriptAction:(id)sender {
    [self sendEventWithCode:'Reld'];
}


- (IBAction)stopLoadingScriptAction:(id)sender {
    [self sendEventWithCode:'Stop'];
}


- (IBAction)zoomInScriptAction:(id)sender {
    [self sendEventWithCode:'ZoIn'];
}


- (IBAction)zoomOutScriptAction:(id)sender {
    [self sendEventWithCode:'ZoOt'];
}


- (IBAction)actualSizeScriptAction:(id)sender {
    [self sendEventWithCode:'ActS'];
}

@end