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

#import <Cocoa/Cocoa.h>

@class CRTweet;

extern NSString *const CRAvatarDidLoadNotification;

@interface NSObject (CRAvatarNotifications)
- (void)avatarDidLoad:(NSNotification *)n;
@end

extern const CGFloat kCRAvatarSide;
extern const CGFloat kCRAvatarCornerRadius;

@interface CRAvatarCache : NSObject {
    NSMutableDictionary *cache;
    NSMutableArray *keyAge;
}

+ (CRAvatarCache *)instance;

- (NSImage *)avatarForTweet:(CRTweet *)tweet sender:(id)sender;
@end
