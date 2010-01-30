//
//  CRTweet.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 1/30/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

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
