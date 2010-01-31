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

#import "CRThreadViewController.h"
#import "CRTwitterPlugIn.h"
#import "CRTwitterUtils.h"
#import "CRTweet.h"
#import <WebKit/WebKit.h>

@interface CRThreadViewController ()
- (void)prepareAndDisplayTweets;
- (void)appendTweetToList;
- (void)fetchInReplyToStatus;
- (void)done;

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
#pragma mark ListViewDataSource

- (NSUInteger)numberOfItemsInListView:(TDListView *)lv {
    NSUInteger c = [tweets count];
    return c;
}


#pragma mark -
#pragma mark Private

- (void)prepareAndDisplayTweets {
    NSAssert(tweet, @"");
    self.tweets = [NSMutableArray array];
    [self appendTweetToList];
}


- (void)appendTweetToList {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(appendStatusToMarkup) withObject:nil waitUntilDone:NO];
        return;
    }    

    [tweets addObject:tweet];
    [listView reloadData];

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
    [tweet updateAgo];
    
    [self appendTweetToList];
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
    [super requestFailed:connectionIdentifier withError:error];
    [self done];
}


- (void)done {
    self.navigationItem.rightBarButtonItem = nil;
}


- (NSString *)formattedDate:(NSString *)inDate {
    return CRFormatDateString(inDate);
}

@synthesize tweet;
@end
