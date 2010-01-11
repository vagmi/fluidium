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

#import "NSImage+FUAdditions.h"
#import "FUUtils.h"

@implementation NSImage (FUAdditions)

- (NSImage *)scaledImageOfSize:(NSSize)size {
    return [self scaledImageOfSize:size alpha:1];
}


- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha {
    return [self scaledImageOfSize:size alpha:alpha hiRez:YES];
}


- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha hiRez:(BOOL)hiRez {
    return [self scaledImageOfSize:size alpha:alpha hiRez:hiRez clippingPath:nil];
}


- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha hiRez:(BOOL)hiRez cornerRadius:(CGFloat)radius {
    NSBezierPath *path = FUGetRoundRect(NSMakeRect(0, 0, size.width, size.height), radius, 1);
    return [self scaledImageOfSize:size alpha:alpha hiRez:hiRez clippingPath:path];
}


- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha hiRez:(BOOL)hiRez clippingPath:(NSBezierPath *)path {
    NSImage *result = [[[NSImage alloc] initWithSize:size] autorelease];
    [result lockFocus];
    
    // get context
    NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
    
    // store previous state
    BOOL savedAntialias = [currentContext shouldAntialias];
    NSImageInterpolation savedInterpolation = [currentContext imageInterpolation];
    
    // set new state
    [currentContext setShouldAntialias:YES];
    NSImageInterpolation rez = hiRez ? NSImageInterpolationHigh : NSImageInterpolationDefault;
    [currentContext setImageInterpolation:rez];

    // set clip
    [path setClip];
    
    // draw image
    NSSize fromSize = [self size];
    [self drawInRect:NSMakeRect(0, 0, size.width, size.height) fromRect:NSMakeRect(0, 0, fromSize.width, fromSize.height) operation:NSCompositeSourceOver fraction:alpha];
    
    // restore state
    [currentContext setShouldAntialias:savedAntialias];
    [currentContext setImageInterpolation:savedInterpolation];
    
    [result unlockFocus];
    return result;
}

@end
