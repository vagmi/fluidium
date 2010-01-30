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

#import "CRTextView.h"
#import "CRTwitterPlugIn.h"

@implementation CRTextView

- (void)clickedOnLink:(id)link atIndex:(NSUInteger)charIndex {
    NSURL *URL = nil;
    if ([link isKindOfClass:[NSURL class]]) {
        URL = link;
    } else if ([link isKindOfClass:[NSString class]]) {
        URL = [NSURL URLWithString:link];
    } else {
        NSAssert(0, @"link should be a url or string");
    }
    
    if (URL) {
        [[CRTwitterPlugIn instance] openURL:URL];
    } else {
        NSLog(@"could not activate link: %@", link);
    }
}

@end
