//
//  CRTweet.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 1/30/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

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
//    avatarURLString = "http://a3.twimg.com/profile_images/579844959/Photo_on_2009-12-17_at_15.46__2_normal.jpg";
//    "created_at" = 2010-01-29 22:16:06 -0800;
//    doesMentionMe = 0;
//    id = 8402242462;
//    isReply = 0;
//    name = "Tim Trueman";
//    text = "This is an interesting idea <a class='url' href='http://www.techcrunch.com/2010/01/29/first-round-capital-entrepreneur-exchange-fund/' onclick='cruz.linkClicked(\"http://www.techcrunch.com/2010/01/29/first-round-capital-entrepreneur-exchange-fund/\"); return false;'>www.techcrunch.com/2010/01/29/fi\U2026</a>";
//    username = timtrueman;
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
