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

#import "NSAppleEventDescriptor+FUAdditions.h"

@implementation NSAppleEventDescriptor (FUAdditions)

+ (NSAppleEventDescriptor *)descriptorForFluidiumProcess {
    OSErr err = noErr;
    ProcessSerialNumber selfPSN = { 0, kCurrentProcess };
    if (err) {
        return nil;
    } else {
        return [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&selfPSN length:sizeof(selfPSN)];
    }
}


+ (NSAppleEventDescriptor *)appleEventForFluidiumEventID:(FourCharCode)code {
    return [self appleEventForClass:'FuSS' eventID:code];
}


+ (NSAppleEventDescriptor *)appleEventForClass:(FourCharCode)class eventID:(FourCharCode)code {
    NSAppleEventDescriptor *targetDesc = [NSAppleEventDescriptor descriptorForFluidiumProcess];
    return [NSAppleEventDescriptor appleEventWithEventClass:class eventID:code targetDescriptor:targetDesc returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
}


+ (OSErr)sendVerbFirstEventWithFluidiumEventID:(FourCharCode)code {
    NSAppleEventDescriptor *someAE = [NSAppleEventDescriptor appleEventForFluidiumEventID:code];
    
    //NSAppleEventDescriptor *directObjDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeWildCard bytes:<#(const void *)bytes#> length:<#(NSUInteger)byteCount#>
    //[someAE setDescriptor:directObjDesc forKeyword:keyDirectObject];
    
    return [someAE sendFluidiumAppleEvent];
}


+ (OSErr)sendVerbFirstEventWithCoreEventID:(FourCharCode)code {
    NSAppleEventDescriptor *someAE = [NSAppleEventDescriptor appleEventForClass:'core' eventID:code];
    
    //NSAppleEventDescriptor *directObjDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeWildCard bytes:<#(const void *)bytes#> length:<#(NSUInteger)byteCount#>
    //[someAE setDescriptor:directObjDesc forKeyword:keyDirectObject];
    
    return [someAE sendFluidiumAppleEvent];
}


- (OSErr)sendFluidiumAppleEvent {
    const AppleEvent *aeDesc = [self aeDesc];

    OSErr err = noErr; 
    err = AESendMessage(aeDesc, NULL, kAENoReply|kAENeverInteract, kAEDefaultTimeout);
    return err;
}

@end
