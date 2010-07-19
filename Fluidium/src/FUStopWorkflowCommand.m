//
//  FUStopWorkflowCommand.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 7/18/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "FUStopWorkflowCommand.h"
#import "FUDocumentController.h"
#import "FakeDocument.h"

@implementation FUStopWorkflowCommand

- (id)performDefaultImplementation {
    FUDocument *doc = [self directParameter];
    if (!doc) {
        doc = [[FUDocumentController instance] frontDocument];
    }
    [doc handleStopWorkflowCommand:self];
    return nil;
}

@end
