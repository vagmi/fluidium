//
//  FUScriptUtils.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/18/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "FUScriptUtils.h"

AEAddressDesc FUCreateTargetProcessDesc(OSErr *outErr) {
    AEAddressDesc addrDesc;
    ProcessSerialNumber selfPSN = { 0, kCurrentProcess };
    if (outErr) {
        *outErr = noErr;
    }
    
    *outErr = AECreateDesc(typeProcessSerialNumber, &selfPSN, sizeof(selfPSN), &addrDesc);
    
    return addrDesc;
}
