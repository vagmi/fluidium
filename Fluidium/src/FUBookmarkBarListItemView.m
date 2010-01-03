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

#import "FUBookmarkBarListItemView.h"
#import "FUBookmarkBarButton.h"

@implementation FUBookmarkBarListItemView

+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self);
}


- (id)init {
    if (self = [super initWithFrame:NSZeroRect reuseIdentifier:[[self class] reuseIdentifier]]) {
        self.button = [[[FUBookmarkBarButton alloc] initWithFrame:NSMakeRect(0, 3, 0, 17)] autorelease];
        [button setAutoresizingMask:NSViewWidthSizable];
        [self addSubview:button];
    }
    return self;
}


- (void)dealloc {
    self.button = nil;
    [super dealloc];
}

@synthesize button;
@end
