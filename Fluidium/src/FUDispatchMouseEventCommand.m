//
//  FUDispatchMouseEventCommand.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 7/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "FUDispatchMouseEventCommand.h"
#import "FUDocumentController.h"
#import "FUTabController+Scripting.h"

@implementation FUDispatchMouseEventCommand

- (id)performDefaultImplementation {
    NSDictionary *args = [self evaluatedArguments];
    
    FUTabController *tc = [args objectForKey:@"tabController"]; // may be nil
    if (!tc) {
        tc = [[FUDocumentController instance] frontTabController];
    }
    [tc handleDispatchMouseEventCommand:self];
    
    return nil;
}

@end
