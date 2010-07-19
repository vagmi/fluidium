//
//  FURunWorkflowCommand.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 7/18/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "FURunWorkflowCommand.h"
#import "FUDocumentController.h"
#import "FakeDocument.h"

@implementation FURunWorkflowCommand

- (id)performDefaultImplementation {
    FUDocument *doc = [self directParameter];
    if (!doc) {
        doc = [[FUDocumentController instance] frontDocument];
    }
    [doc handleRunWorkflowCommand:self];
    return nil;
}

@end
