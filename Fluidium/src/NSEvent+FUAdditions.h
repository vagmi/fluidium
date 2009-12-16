//
//  NSEvent+FUAdditions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/4/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSEvent (FUAdditions)
- (BOOL)isKeyUpOrDown;
- (BOOL)is3rdButtonClick;
- (BOOL)isCommandKeyPressed;
- (BOOL)isShiftKeyPressed;
- (BOOL)isOptionKeyPressed;
- (BOOL)isEscKeyPressed;
- (BOOL)isReturnKeyPressed;
- (BOOL)isEnterKeyPressed;
@end
