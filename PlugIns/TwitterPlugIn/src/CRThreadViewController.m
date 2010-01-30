//
//  CRThreadViewController.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/8/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRThreadViewController.h"
#import "CRTwitterPlugIn.h"
#import "CRTwitterUtils.h"
#import "CRTweet.h"
#import <WebKit/WebKit.h>

@interface CRThreadViewController ()
- (NSDictionary *)varsWithStatus:(NSDictionary *)d;
- (void)prepareAndDisplayTweets;
- (void)appendTweetToList;
- (void)fetchInReplyToStatus;
- (void)done;

- (NSString *)markedUpStatus:(NSString *)inStatus;
- (NSString *)formattedDate:(NSString *)inDate;    
@end

@implementation CRThreadViewController

- (id)init {
    return [self initWithNibName:@"CRThreadView" bundle:[NSBundle bundleForClass:[CRThreadViewController class]]];
}


- (id)initWithNibName:(NSString *)s bundle:(NSBundle *)b {
    if (self = [super initWithNibName:s bundle:b]) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}


- (void)dealloc {
    self.tweet = nil;
    self.usernameA = nil;
    self.usernameB = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark UMEViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[[UMEActivityBarButtonItem alloc] init] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = NO;

    [self prepareAndDisplayTweets];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
}


#pragma mark -
#pragma mark Private

- (void)setUpTemplateEngine {
}


- (NSDictionary *)varsWithStatus:(NSDictionary *)d {
    id displayUsernames = [[NSUserDefaults standardUserDefaults] objectForKey:kCRTwitterDisplayUsernamesKey];
    
    NSDictionary *vars = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSArray arrayWithObject:d], @"statuses",
                          displayUsernames, @"displayUsernames",
                          //CRDefaultProfileImageURLString(), @"defaultAvatarURLString",
                          nil];
    
    return vars;
}


- (void)prepareAndDisplayTweets {
    NSAssert(tweet, @"");
    
//    NSMutableDictionary *d = [[status mutableCopy] autorelease];
//    [d setObject:[NSNumber numberWithBool:NO] forKey:@"isReply"];
//    
//    NSDictionary *vars = [self varsWithStatus:d];
//    NSString *htmlStr = [templateEngine processTemplate:templateString withVariables:vars];
//    [[webView mainFrame] loadHTMLString:htmlStr baseURL:nil];
}


- (void)appendTweetToList {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(appendStatusToMarkup) withObject:nil waitUntilDone:NO];
        return;
    }    

    // TODO
//    NSMutableDictionary *d = [[tweet mutableCopy] autorelease];
//    [d setObject:[NSNumber numberWithBool:NO] forKey:@"isReply"];

//    NSDictionary *vars = [self varsWithStatus:d];
//    NSString *newStatusHTMLStr = [templateEngine processTemplate:statusTemplateString withVariables:vars];
//
//    DOMDocument *doc = [[webView mainFrame] DOMDocument];
//    
//    DOMHTMLElement *threadEl = (DOMHTMLElement *)[doc getElementById:@"thread"];
//    [super appendMarkup:newStatusHTMLStr toElement:threadEl];
    
    [self fetchInReplyToStatus];
}


- (void)fetchInReplyToStatus {
    NSNumber *statusID = tweet.inReplyToIdentifier;
    if (statusID) {
        [twitterEngine getUpdate:[statusID longLongValue]];
    } else {
        [self done];
    }
}


- (void)statusesReceived:(NSArray *)inStatuses forRequest:(NSString *)requestID {
    NSMutableArray *newTweets = [super tweetsFromStatuses:inStatuses];

    if (![newTweets count]) {
        return;
    }
    
    NSAssert(1 == [newTweets count], @"");
    
    self.tweet = [newTweets objectAtIndex:0];
//    [d setObject:CRFormatDate([tweet objectForKey:@"created_at"]) forKey:@"ago"];
    
    [self appendTweetToList];
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
    [super requestFailed:connectionIdentifier withError:error];
    [self done];
}


- (void)done {
    self.navigationItem.rightBarButtonItem = nil;
}


- (NSString *)markedUpStatus:(NSString *)inStatus {
    NSArray *mentions = nil;
    return CRMarkedUpStatus(inStatus, &mentions);
}


- (NSString *)formattedDate:(NSString *)inDate {
    return CRFormatDateString(inDate);
}


// TODO
//- (void)webView:(WebView *)wv didFinishLoadForFrame:(WebFrame *)frame {
//    if (frame != [wv mainFrame]) return;
//
//    [self fetchInReplyToStatus];
//}


#pragma mark -
#pragma mark WebScripting

- (void)linkClicked:(NSString *)URLString {
    [self openURLInNewTabOrWindow:URLString];
}


- (void)avatarClicked:(NSString *)username {
    [self openUserPageInNewTabOrWindow:username];
}


- (void)usernameClicked:(NSString *)username {
    [super handleUsernameClicked:username];
}


+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
    return YES;
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel {
    if (@selector(avatarClicked:) == sel ||
        @selector(linkClicked:) == sel ||
        @selector(usernameClicked:) == sel) {
        return NO;
    } else {
        return YES;
    }
}


+ (NSString *)webScriptNameForKey:(const char *)name {
    return nil;
}


+ (NSString *)webScriptNameForSelector:(SEL)sel {
    if (@selector(usernameClicked:) == sel) {
        return @"usernameClicked";
    } else if (@selector(avatarClicked:) == sel) {
        return @"avatarClicked";
    } else if (@selector(linkClicked:) == sel) {
        return @"linkClicked";
    } else {
        return nil;
    }
}

@synthesize tweet;
@synthesize usernameA;
@synthesize usernameB;
@end
