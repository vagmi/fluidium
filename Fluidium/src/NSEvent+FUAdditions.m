//  Copyright 2009 Todd Ditchendorf
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

#import "NSEvent+FUAdditions.h"
#import "FUUtils.h"

#define ESC 53
#define RETURN 36
#define ENTER 76

@implementation NSEvent (FUAdditions)

- (BOOL)isMouseDown {
    return (NSLeftMouseDown == [self type] || NSRightMouseDown == [self type]);
}


- (BOOL)isMouseMoved {
    return (NSMouseMoved == [self type]);
}


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
