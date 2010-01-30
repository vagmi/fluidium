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

#import <Cocoa/Cocoa.h>

@interface CRTweet : NSObject {
    NSNumber *identifier;
    NSNumber *inReplyToIdentifier;
    NSString *name;
    NSString *username;
    NSString *text;
    NSString *ago;
    NSString *avatarURLString;
    BOOL byMe;
    BOOL mentionMe;
    BOOL reply;
    
    NSDate *createdAt;
}

+ (CRTweet *)tweetFromDictionary:(NSDictionary *)d;

- (void)updateAgo;

@property (nonatomic, readonly, retain) NSNumber *identifier;
@property (nonatomic, readonly, retain) NSNumber *inReplyToIdentifier;
@property (nonatomic, readonly, retain) NSString *name;
@property (nonatomic, readonly, retain) NSString *username;
@property (nonatomic, readonly, retain) NSString *text;
@property (nonatomic, readonly, retain) NSString *ago;
@property (nonatomic, readonly, retain) NSString *avatarURLString;
@property (nonatomic, readonly, getter=isByMe) BOOL byMe;
@property (nonatomic, readonly, getter=isMentionMe) BOOL mentionMe;
@property (nonatomic, readonly, getter=isReply) BOOL reply;
@end
