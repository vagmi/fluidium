//
//  FakeDocument.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 6/27/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FUWindowController;

@interface FUDocument : NSDocument {
    FUWindowController *windowController;
    id workflow;
}

- (IBAction)showActionLibrary:(id)sender;
- (IBAction)showWorkflow:(id)sender;
- (IBAction)runWorkflow:(id)sender;
- (IBAction)stopWorkflow:(id)sender;

- (void)windowControllerDidShowVisiblePlugIns:(FUWindowController *)wc;

- (id)fakePlugInViewController;

@property (nonatomic, retain) FUWindowController *windowController;
@property (nonatomic, retain) id workflow;
@end
