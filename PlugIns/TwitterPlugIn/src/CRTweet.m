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

#import "CRTweet.h"
#import "CRTwitterUtils.h"

@interface CRTweet ()
@property (nonatomic, readwrite, retain) NSNumber *identifier;
@property (nonatomic, readwrite, retain) NSNumber *inReplyToIdentifier;
@property (nonatomic, readwrite, retain) NSString *name;
@property (nonatomic, readwrite, retain) NSString *username;
@property (nonatomic, readwrite, retain) NSString *text;
@property (nonatomic, readwrite, retain) NSString *ago;
@property (nonatomic, readwrite, retain) NSString *avatarURLString;
@property (nonatomic, readwrite, getter=isByMe) BOOL byMe;
@property (nonatomic, readwrite, getter=isMentionMe) BOOL mentionMe;
@property (nonatomic, readwrite, getter=isReply) BOOL reply;

@property (nonatomic, retain) NSDate *createdAt;
@end

@implementation CRTweet

//{
//    avatarURLString = "http://a3.twimg.com/profile_images/579844959/XXX.jpg";
//    "created_at" = 2010-01-29 22:16:06 -0800;
//    doesMentionMe = 0;
//    id = 8402242462;
//    isReply = 0;
//    name = "Foo Bar";
//    text = "OHAI THIS IS A TWEET";
//    username = foobar;
//    writtenByMe = 0;
//    inReplyToIdentifier = 8402242462;
//}

+ (CRTweet *)tweetFromDictionary:(NSDictionary *)d {
    CRTweet *tweet = [[[CRTweet alloc] init] autorelease];
    tweet.identifier = [d objectForKey:@"id"];
    tweet.inReplyToIdentifier = [d objectForKey:@"inReplyToIdentifier"];
    tweet.name = [d objectForKey:@"name"];
    tweet.username = [d objectForKey:@"username"];
    tweet.text = [d objectForKey:@"text"];
    tweet.avatarURLString = [d objectForKey:@"avatarURLString"];
    tweet.byMe = [[d objectForKey:@"isByMe"] boolValue];
    tweet.mentionMe = [[d objectForKey:@"isMentionMe"] boolValue];
    tweet.reply = [[d objectForKey:@"isReply"] boolValue];

    tweet.createdAt = [d objectForKey:@"created_at"];
    [tweet updateAgo];
    
    return tweet;
}


- (void)dealloc {
    self.identifier = nil;
    self.inReplyToIdentifier = nil;
    self.name = nil;
    self.username = nil;
    self.text = nil;
    self.ago = nil;
    self.avatarURLString = nil;
    self.createdAt = nil;
    [super dealloc];
}


- (void)updateAgo {
    self.ago = CRFormatDate(createdAt);
}

@synthesize identifier;
@synthesize inReplyToIdentifier;
@synthesize name;
@synthesize username;
@synthesize text;
@synthesize ago;
@synthesize avatarURLString;
@synthesize byMe;
@synthesize mentionMe;
@synthesize reply;
@synthesize createdAt;
@end
