//
//  CRBaseViewController.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/8/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRBaseViewController.h"
#import "CRTwitterPlugIn.h"
#import "CRTwitterUtils.h"
#import "CRTimelineViewController.h"
#import "CRThreadViewController.h"
#import "CRTweet.h"

@implementation CRBaseViewController

- (id)initWithNibName:(NSString *)s bundle:(NSBundle *)b {
    if (self = [super initWithNibName:s bundle:b]) {
        [self setUpTwitterEngine];
    }
    return self;
}


- (void)dealloc {
    self.listView = nil;
    self.twitterEngine = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark TDListViewDataSource

- (NSUInteger)numberOfItemsInListView:(TDListView *)lv {
    NSAssert1(0, @"must implement %s", __PRETTY_FUNCTION__);
    return 0;
}


- (id)listView:(TDListView *)lv itemAtIndex:(NSUInteger)i {
    NSAssert1(0, @"must implement %s", __PRETTY_FUNCTION__);
    return nil;
}


#pragma mark -
#pragma mark MGTwitterEngine

- (void)setUpTwitterEngine {
    self.twitterEngine = nil;
    
    NSString *username = [[CRTwitterPlugIn instance] selectedUsername];
    if (![username length]) {
        NSArray *usernames = [[CRTwitterPlugIn instance] usernames];
        if ([usernames count]) {
            username = [usernames objectAtIndex:0];
            [[CRTwitterPlugIn instance] setSelectedUsername:username];
        }
    }
    NSString *password = nil;
    if ([username length]) {
        password = [[CRTwitterPlugIn instance] passwordFor:username];
    }
    
    if (!username || !password) {
        return;
    }
    
    self.twitterEngine = [[[MGTwitterEngine alloc] initWithDelegate:self] autorelease];
    [twitterEngine setUsername:username password:password];
}


- (void)requestSucceeded:(NSString *)connectionIdentifier {
    //    NSLog(@"Request succeeded for connectionIdentifier = %@", connectionIdentifier);
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
    NSLog(@"Request failed for connectionIdentifier = %@, error = %@ (%@)", 
          connectionIdentifier, 
          [error localizedDescription], 
          [error userInfo]);
}


- (NSMutableArray *)tweetsFromStatuses:(NSArray *)inStatuses {
    //NSLog(@"Got statuses for %@:\r%@", requestID, inStatuses);
    //NSLog(@"Got statuses for %@:\r %d", requestID, [inStatuses count]);
    
    NSMutableArray *tweets = [NSMutableArray arrayWithCapacity:[inStatuses count]];
    
    NSString *myname = [[[CRTwitterPlugIn instance] selectedUsername] lowercaseString];
    NSString *atmyname = [NSString stringWithFormat:@"@%@", myname];
    NSString *defaultAvatarURLString = CRDefaultProfileImageURLString();
    
    for (NSDictionary *inStatus in inStatuses) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        NSDictionary *inUser = [inStatus objectForKey:@"user"];
        
        // id
        NSNumber *statusID = [inStatus objectForKey:@"id"];
        [d setObject:statusID forKey:@"id"];
        
        // date
        [d setObject:[inStatus objectForKey:@"created_at"] forKey:@"created_at"];
        
        // avatarURLString
        NSString *avatarURLString = [inUser objectForKey:@"profile_image_url"];
        if (![avatarURLString length])  {
            avatarURLString = defaultAvatarURLString;
        }
        
        [d setObject:avatarURLString forKey:@"avatarURLString"];
        
        // isMentionMe
        NSString *text = [inStatus objectForKey:@"text"];
        BOOL isMentionMe = [text rangeOfString:atmyname options:NSCaseInsensitiveSearch].length;
        [d setObject:[NSNumber numberWithBool:isMentionMe] forKey:@"isMentionMe"];
        
        // markup status
        NSArray *mentions = nil;
        NSAttributedString *attributedText = CRAttributedStatus(text, &mentions);
        if (![attributedText length]) {
            attributedText = CRDefaultAttributedStatus(text);
        }
        [d setObject:attributedText forKey:@"attributedText"];
        [d setObject:text forKey:@"text"];
        
        BOOL isReply = NO;
        NSNumber *inReplyToStatusID = [inStatus objectForKey:@"in_reply_to_status_id"];
        if (inReplyToStatusID) {
            isReply = YES;
            [d setObject:inReplyToStatusID forKey:@"inReplyToIdentifier"];
        }
        [d setObject:[NSNumber numberWithBool:isReply] forKey:@"isReply"];
        
        // name/username
        [d setObject:[inUser objectForKey:@"name"] forKey:@"name"];
        [d setObject:[inUser objectForKey:@"screen_name"] forKey:@"username"];
        
        BOOL writtenByMe = [[[d objectForKey:@"username"] lowercaseString] isEqualToString:myname];
        [d setObject:[NSNumber numberWithBool:writtenByMe] forKey:@"isByMe"];
        
        [tweets addObject:[CRTweet tweetFromDictionary:d]];
    }
    
    return tweets;
}


#pragma mark -
#pragma mark WebScripting Bridge

- (void)openUserPageInNewTabOrWindow:(NSString *)username {
    [self openURLInNewTabOrWindow:[NSString stringWithFormat:@"http://twitter.com/%@", username]];
}


- (void)openURLInNewTabOrWindow:(NSString *)URLString {
    BOOL inTab = [[CRTwitterPlugIn instance] tabbedBrowsingEnabled];
    [self openURLString:URLString inNewTab:inTab];
}


- (void)openURLString:(NSString *)URLString inNewTab:(BOOL)inTab {
    [self openURL:[NSURL URLWithString:URLString] inNewTab:inTab];
}


- (void)openURL:(NSURL *)URL inNewTab:(BOOL)inTab {
    NSEvent *evt = [NSApp currentEvent];
    
    BOOL shiftKeyWasPressed = [[CRTwitterPlugIn instance] wasShiftKeyPressed:[evt modifierFlags]];    
    BOOL inForeground = [[NSUserDefaults standardUserDefaults] boolForKey:kCRTwitterSelectNewTabsAndWindowsKey];
    if (shiftKeyWasPressed) {
        inForeground = !inForeground;
    }
    
    if (inTab) {
        [[CRTwitterPlugIn instance] openURL:URL inNewTabInForeground:inForeground];
    } else {
        [[CRTwitterPlugIn instance] openURL:URL inNewWindowInForeground:inForeground];
    }
}


- (void)pushTimelineFor:(NSString *)username {
    CRTimelineViewController *vc = [[[CRTimelineViewController alloc] initWithType:CRTimelineTypeUser] autorelease];
    vc.title = username;
    vc.displayedUsername = username;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)handleUsernameClicked:(NSString *)username {
    NSEvent *evt = [NSApp currentEvent];
    
    BOOL middleButtonClick = (2 == [evt buttonNumber]);
    BOOL commandKeyWasPressed = [[CRTwitterPlugIn instance] wasCommandKeyPressed:[evt modifierFlags]];
    BOOL cmdClick = (commandKeyWasPressed || middleButtonClick);
    
    if (cmdClick) {
        [self openUserPageInNewTabOrWindow:username];
    } else {
        [self pushTimelineFor:username];
    }    
}

@synthesize listView;
@synthesize twitterEngine;
@end
