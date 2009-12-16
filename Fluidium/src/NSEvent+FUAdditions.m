//
//  NSEvent+FUAdditions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/4/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "NSEvent+FUAdditions.h"
#import "FUUtils.h"

#define ESC 53
#define RETURN 36
#define ENTER 76

@implementation NSEvent (FUAdditions)

- (BOOL)isKeyUpOrDown {
    return (NSKeyUp == [self type] || NSKeyDown == [self type]);
}


- (BOOL)is3rdButtonClick {
    return 2 == [self buttonNumber];
}


- (BOOL)isCommandKeyPressed {
    return FUIsCommandKeyPressed([self modifierFlags]);
}


- (BOOL)isShiftKeyPressed {
    return FUIsShiftKeyPressed([self modifierFlags]);
}


- (BOOL)isOptionKeyPressed {
    return FUIsOptionKeyPressed([self modifierFlags]);
}


- (BOOL)isEscKeyPressed {
    return [self isKeyUpOrDown] && ESC == [self keyCode];
}


- (BOOL)isReturnKeyPressed {
    return [self isKeyUpOrDown] && RETURN == [self keyCode];
}


- (BOOL)isEnterKeyPressed {
    return [self isKeyUpOrDown] && ENTER == [self keyCode];
}

@end
