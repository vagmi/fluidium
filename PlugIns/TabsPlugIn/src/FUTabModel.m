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

#import "FUTabModel.h"

@interface FUTabModel ()
- (NSUInteger)incrementChangeCount;
@end

@implementation FUTabModel

+ (FUTabModel *)modelWithPlist:(NSDictionary *)plist {
    FUTabModel *m = [[[self alloc] init] autorelease];
    m.title = [plist objectForKey:@"title"];
    m.URLString = [plist objectForKey:@"URLString"];
    m.index = [[plist objectForKey:@"index"] integerValue];
    m.selected = [[plist objectForKey:@"selected"] boolValue];
    return m;
}


- (void)dealloc {
    self.image = nil;
    self.scaledImage = nil;
    self.title = nil;
    self.URLString = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUTabModel %p %@>", self, title];
}


- (NSDictionary *)plist {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:3];
    [d setObject:title forKey:@"title"];
    [d setObject:URLString forKey:@"URLString"];
    [d setObject:[NSNumber numberWithInteger:index] forKey:@"index"];
    [d setObject:[NSNumber numberWithInteger:selected] forKey:@"selected"];
    return d;
}


- (NSUInteger)incrementChangeCount {
    return ++changeCount;
}


- (BOOL)wantsNewImage {
    [self incrementChangeCount];
    if (estimatedProgress > .9) {
        self.estimatedProgress = 1.0;
        return YES;
    } else {
        // only update web image every third notification
        return (0 == changeCount % 3);
    }
}

@synthesize image;
@synthesize scaledImage;
@synthesize title;
@synthesize URLString;
@synthesize index;
@synthesize estimatedProgress;
@synthesize loading;
@synthesize selected;
@end
