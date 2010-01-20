//
//  FUWindowController+Scripting.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/19/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "FUWindowController+Scripting.h"
#import "FUDocument+Scripting.h"

@implementation FUWindowController (Scripting)

// override this method to send close events for background tabs thru the scripting architecture for recording
- (void)removeTabControllerAtIndex:(NSUInteger)i {
    [[self document] removeTabControllerAtIndex:i];
}

@end
