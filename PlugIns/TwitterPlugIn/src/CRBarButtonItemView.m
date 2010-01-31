//  Copyright 2010 Todd Ditchendorf
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

#import "CRBarButtonItemView.h"
#import <UMEKit/UMEBarButtonItem.h>

static NSImage *sLeftImagePlain = nil;
static NSImage *sCenterImagePlain = nil;
static NSImage *sRightImagePlain = nil;

@implementation CRBarButtonItemView

+ (void)initialize {
    if ([CRBarButtonItemView class] == self) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        NSBundle *b = [NSBundle bundleForClass:[UMEBarButtonItem class]];
        
        sLeftImagePlain     = [[NSImage alloc] initWithContentsOfFile:[b pathForImageResource:@"barbuttonitem_plain_bg_01"]];
        sCenterImagePlain   = [[NSImage alloc] initWithContentsOfFile:[b pathForImageResource:@"barbuttonitem_plain_bg_02"]];
        sRightImagePlain    = [[NSImage alloc] initWithContentsOfFile:[b pathForImageResource:@"barbuttonitem_plain_bg_03"]];
        
        [pool release];
    }
}


- (BOOL)isFlipped {
    return YES;
}


- (void)drawRect:(NSRect)r {
    // draw bg image
    NSImage *leftImage = sLeftImagePlain;
    NSImage *centerImage = sCenterImagePlain;
    NSImage *rightImage = sRightImagePlain;

    [leftImage setFlipped:[self isFlipped]];
    [centerImage setFlipped:[self isFlipped]];
    [rightImage setFlipped:[self isFlipped]];
    
    NSDrawThreePartImage(r, leftImage, centerImage, rightImage, NO, NSCompositeSourceOver, 1.0, NO);
}
    
@end
