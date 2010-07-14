//
//  CaptureWebPageCommand.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 7/14/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "CaptureWebPageCommand.h"
#import "FUTabController+Scripting.h"

@implementation FUCaptureWebPageCommand

- (id)performDefaultImplementation {
    return [[self targetTabController] handleCaptureWebPageCommand:self];
//    NSDictionary *args = [self evaluatedArguments];
//    
//    FUTabController *tc = [args objectForKey:@"tabController"]; // may be nil
//    if (!tc) {
//        tc = [[FUDocumentController instance] frontTabController];
//    }
//    [tc handleCaptureWebPageCommand:self];
//    
//    return nil;
}

@end
