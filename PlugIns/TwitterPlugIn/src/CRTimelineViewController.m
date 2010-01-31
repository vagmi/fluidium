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

#import "CRTimelineViewController.h"
#import "CRTwitterUtils.h"
#import "CRTwitterPlugIn.h"
#import "CRThreadViewController.h"
#import "CRBarButtonItemView.h"
#import "CRTweet.h"
#import "CRTweetListItem.h"
#import <Fluidium/FUPlugInAPI.h>
#import "WebURLsWithTitles.h"
//#import <WebKit/WebKit.h>

#define DEFAULT_FETCH_INTERVAL_MINS 3
#define ENABLE_INTERVAL_MINS .5

#define DEFAULT_FETCH_INTERVAL_SECS (DEFAULT_FETCH_INTERVAL_MINS * 60)
#define ENABLE_INTERVAL_SECS (ENABLE_INTERVAL_MINS * 60)

#define DEFAULT_STATUS_FETCH_COUNT 40

#define DATES_INTERVAL_SECS 30

#define WebURLsWithTitlesPboardType     @"WebURLsWithTitlesPboardType"

@interface CRTimelineViewController ()
- (id)initWithNibName:(NSString *)s bundle:(NSBundle *)b type:(CRTimelineType)t;

- (void)setUpNavBar;
- (void)showRefreshBarButtonItem;
- (void)showProgressBarButtonItem;
- (void)refreshTitle;
- (void)refreshWithSelectedUsername;
- (void)selectedUsernameChanged;

// fetching
- (void)beginFetchLoop;
- (BOOL)isTooSoonToFetchAgain;
- (void)killFetchTimer;
- (void)startFetchTimerWithDefaultDelay;
- (void)startFetchTimerWithDelay:(NSTimeInterval)delaySecs;
- (void)fetchTimerFired:(NSTimer *)t;
- (void)fetchLatestTimeline;
- (void)fetchEarlierTimeline;

- (void)killEnableTimer;
- (void)startEnableTimer;
- (void)enableTimerFired:(NSTimer *)t;
- (void)enableFetching;
- (void)showProgressBarButtonItem;
- (void)updateDisplayedDates;

- (BOOL)isAppendRequestID:(NSString *)reqID;
- (void)setAppend:(BOOL)append forRequestID:(NSString *)reqID;

- (void)openLinkInNewTab:(BOOL)inTab;
- (void)pushThread:(NSString *)statusID;

- (void)killDatesTimer;
- (void)startDatesLoop;

- (NSURL *)defaultProfileImageURL;
- (void)clearList;
- (void)prepareAndDisplayTweets:(id)appendObj;

- (unsigned long long)latestID;
- (unsigned long long)earliestID;

@property (nonatomic, retain) NSURL *defaultProfileImageURL;
@property (nonatomic, retain) NSMutableArray *tweets;
@property (nonatomic, retain) NSMutableArray *newTweets;
@property (nonatomic, retain) NSMutableDictionary *tweetTable;
@property (nonatomic, retain) NSArray *tweetSortDescriptors;
@property (nonatomic, retain) NSTimer *fetchTimer;
@property (nonatomic, retain) NSTimer *enableTimer;
@property (nonatomic, retain) NSTimer *datesTimer;
@property (nonatomic, retain) NSMutableDictionary *appendTable;
@end

@implementation CRTimelineViewController

- (id)init {
    return [self initWithType:CRTimelineTypeHome];
}

    
- (id)initWithType:(CRTimelineType)t {
    return [self initWithNibName:@"CRTimelineView" bundle:[NSBundle bundleForClass:[CRTimelineViewController class]] type:t];
}


- (id)initWithNibName:(NSString *)s bundle:(NSBundle *)b {
    return [self initWithNibName:@"CRTimelineView" bundle:[NSBundle bundleForClass:[CRTimelineViewController class]] type:CRTimelineTypeHome];
}


- (id)initWithNibName:(NSString *)s bundle:(NSBundle *)b type:(CRTimelineType)t {
    if (self = [super initWithNibName:s bundle:b]) {
        type = t;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(selectedUsernameDidChange:)
                                                     name:CRTwitterPlugInSelectedUsernameDidChangeNotification
                                                   object:[CRTwitterPlugIn instance]];

        NSSortDescriptor *desc = [[[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:NO] autorelease];
        self.tweetSortDescriptors = [NSArray arrayWithObject:desc];
        self.tweetTable = [NSMutableDictionary dictionary];
        self.appendTable = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.displayedUsername = nil;
    self.defaultProfileImageURL = nil;
    self.tweets = nil;
    self.newTweets = nil;
    self.tweetTable = nil;
    self.tweetSortDescriptors = nil;
    self.appendTable = nil;
    [self killFetchTimer];
    [self killEnableTimer];
    [self killDatesTimer];
    [super dealloc]; 
}


#pragma mark -
#pragma mark UMEViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNavBar];
    [self refreshWithSelectedUsername];
}


- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (CRTimelineTypeUser != type) {
        NSString *selectedUsername = [[CRTwitterPlugIn instance] selectedUsername];
        if (!displayedUsername) {
            self.displayedUsername = selectedUsername;
        } else {
            if (![displayedUsername isEqualToString:selectedUsername]) {
                [self selectedUsernameChanged];
            }
        }
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    visible = YES;
    
    //if (![webView isLoading]) {
        [self beginFetchLoop];
    //}
    
    [self startDatesLoop];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self killFetchTimer];
    [self killDatesTimer];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    visible = NO;
}


#pragma mark -
#pragma mark View setup

- (void)setUpNavBar {
    
    if (CRTimelineTypeUser == type) {
        
    } else {
        self.navigationItem.backBarButtonItem = [[[UMEBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Home", @"") 
                                                                                   style:UMEBarButtonItemStyleBack 
                                                                                  target:self 
                                                                                  action:@selector(pop:)] autorelease];

        self.navigationItem.leftBarButtonItem = [[[UMEBarButtonItem alloc] initWithBarButtonSystemItem:UMEBarButtonSystemItemUser
                                                                                                target:self
                                                                                                action:@selector(showAccountsPopUp:)] autorelease];

        [self showRefreshBarButtonItem];        
    }

}


- (void)showRefreshBarButtonItem {
    self.navigationItem.rightBarButtonItem = [[[UMEBarButtonItem alloc] initWithBarButtonSystemItem:UMEBarButtonSystemItemRefresh
                                                                                             target:self
                                                                                             action:@selector(fetchLatestStatuses:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = fetchingEnabled;
}


- (void)showProgressBarButtonItem {
    self.navigationItem.rightBarButtonItem = [[[UMEActivityBarButtonItem alloc] init] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}


- (void)refreshTitle {
    switch (type) {
        case CRTimelineTypeHome:
            self.title = [[CRTwitterPlugIn instance] selectedUsername];
            break;
        case CRTimelineTypeMentions:
            self.title = NSLocalizedString(@"Mentions", @"");
            break;
        case CRTimelineTypeUser:
            self.title = displayedUsername;
            break;
        default:
            NSAssert(0, @"");
    }
}


- (void)refreshWithSelectedUsername {
    [self killFetchTimer];
    [self killEnableTimer];
    [self clearList];

    self.tweets = nil;
    
    [self refreshTitle];
    
    fetchingEnabled = YES;
}
             
             
- (void)selectedUsernameChanged {
     self.displayedUsername = [[CRTwitterPlugIn instance] selectedUsername];
     [self setUpTwitterEngine];
     [self refreshWithSelectedUsername];
}


- (BOOL)isAppendRequestID:(NSString *)reqID {
    return [[appendTable objectForKey:reqID] boolValue];
}


- (void)setAppend:(BOOL)append forRequestID:(NSString *)reqID {
    [appendTable setObject:[NSNumber numberWithBool:append] forKey:reqID];
}


#pragma mark -
#pragma mark Actions

- (void)selectedUsernameDidChange:(NSNotification *)n {
    [self selectedUsernameChanged];
}


- (IBAction)accountSelected:(id)sender {
    NSString *newUsername = [sender representedObject];
    NSString *oldUsername = [[CRTwitterPlugIn instance] selectedUsername];
    
    if (![newUsername isEqualToString:oldUsername]) {
        [[CRTwitterPlugIn instance] setSelectedUsername:newUsername];
        [[NSNotificationCenter defaultCenter] postNotificationName:CRTwitterPlugInSelectedUsernameDidChangeNotification object:[CRTwitterPlugIn instance]];
        [self beginFetchLoop];
    }
}


- (IBAction)fetchLatestStatuses:(id)sender {
    if (!visible || [self isTooSoonToFetchAgain]) {
        return;
    }
    [self showProgressBarButtonItem];
    [self killFetchTimer];
    if (CRTimelineTypeUser != type) {
        [self startFetchTimerWithDefaultDelay];
    }
    [self fetchLatestTimeline];
}


- (IBAction)fetchEarlierStatuses:(id)sender {
    [self showProgressBarButtonItem];
    [self fetchEarlierTimeline];
}


- (IBAction)showAccountsPopUp:(id)sender {
    NSEvent *evt = [NSApp currentEvent];
    
    NSRect frame = [[self view] frame];
    NSPoint p = [[self view] convertPointToBase:frame.origin];
    p.y += NSHeight(frame) + 2;
    p.x += 5;
    
    NSEvent *click = [NSEvent mouseEventWithType:[evt type] 
                                        location:p
                                   modifierFlags:[evt modifierFlags] 
                                       timestamp:[evt timestamp] 
                                    windowNumber:[evt windowNumber] 
                                         context:[evt context]
                                     eventNumber:[evt eventNumber] 
                                      clickCount:[evt clickCount] 
                                        pressure:[evt pressure]]; 
    
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];

    NSMenuItem *item = nil;
    for (NSString *username in [[CRTwitterPlugIn instance] usernames]) {
        if ([username length]) {
            item = [[[NSMenuItem alloc] initWithTitle:username action:@selector(accountSelected:) keyEquivalent:@""] autorelease];
            [item setRepresentedObject:username];
            [item setTarget:self];
            [menu addItem:item];
        }
    }
    
    [menu addItem:[NSMenuItem separatorItem]];

    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Add Account...", @"") action:@selector(showPrefs:) keyEquivalent:@""] autorelease];
    [item setTarget:[CRTwitterPlugIn instance]];
    [menu addItem:item];
    
    [NSMenu popUpContextMenu:menu withEvent:click forView:[self view]];
}


- (IBAction)pop:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)usernameButtonClicked:(id)sender {
    NSInteger i = [sender tag];
    NSString *username = [[tweets objectAtIndex:i] username];
    [self handleUsernameClicked:username];
}


- (IBAction)avatarButtonClicked:(id)sender {
    NSInteger i = [sender tag];
    NSString *username = [[tweets objectAtIndex:i] username];
    [self openUserPageInNewTabOrWindow:username];
}


#pragma mark -
#pragma mark Enabling Timer

- (void)killEnableTimer {
    if (enableTimer) {
        [enableTimer invalidate];
        self.enableTimer = nil;
    }
}


- (void)startEnableTimer {
    fetchingEnabled = NO;
    self.enableTimer = [NSTimer scheduledTimerWithTimeInterval:ENABLE_INTERVAL_SECS
                                                        target:self
                                                      selector:@selector(enableTimerFired:)
                                                      userInfo:nil
                                                       repeats:NO];
}

                        
- (void)enableTimerFired:(NSTimer *)t {
    [self enableFetching];
}


- (void)enableFetching {
    [self killEnableTimer];
    fetchingEnabled = YES;
    self.navigationItem.rightBarButtonItem.enabled = fetchingEnabled;
}


#pragma mark -
#pragma mark Fetching

- (void)beginFetchLoop {
    NSTimeInterval fetchDelaySecs = 0;
    
    if ([self isTooSoonToFetchAgain]) {
        fetchDelaySecs = DEFAULT_FETCH_INTERVAL_SECS;
    }
    
    [self performSelector:@selector(fetchLatestStatuses:) withObject:self afterDelay:fetchDelaySecs];
    //    [self startFetchTimerWithDelay:fetchDelaySecs];
}


- (BOOL)isTooSoonToFetchAgain {
    return !fetchingEnabled;
}


- (void)killFetchTimer {
    if (fetchTimer) {
        [fetchTimer invalidate];
        self.fetchTimer = nil;
    }
}


- (void)startFetchTimerWithDefaultDelay {
    [self startFetchTimerWithDelay:DEFAULT_FETCH_INTERVAL_SECS];
}


- (void)startFetchTimerWithDelay:(NSTimeInterval)delaySecs {
    //NSLog(@"starting fetchTimer. delay %d", delaySecs);
    self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:delaySecs
                                                  target:self
                                                selector:@selector(fetchTimerFired:)
                                                userInfo:nil
                                                 repeats:NO];
}


- (void)fetchTimerFired:(NSTimer *)t {
    NSParameterAssert(t == fetchTimer);
    
    if ([t isValid]) {
        [self performSelectorOnMainThread:@selector(fetchLatestStatuses:) withObject:self waitUntilDone:NO];
        //        [self fetchLatestStatuses:self];
    }
}


#pragma mark -
#pragma mark Date Timer

- (void)killDatesTimer {
    if (datesTimer) {
        [datesTimer invalidate];
        self.datesTimer = nil;
    }
}


- (void)startDatesLoop {
    [self killDatesTimer];
    self.datesTimer = [NSTimer scheduledTimerWithTimeInterval:DATES_INTERVAL_SECS 
                                                       target:self 
                                                     selector:@selector(datesTimerFired:) 
                                                     userInfo:nil 
                                                      repeats:YES];
}


- (void)datesTimerFired:(NSTimer *)t {
    NSParameterAssert(t == datesTimer);
    
    if ([t isValid]) {
        [self updateDisplayedDates];
    }
}


#pragma mark -
#pragma mark MGTwitterEngineDelegate

- (unsigned long long)latestID {
    if ([tweets count]) {
        return [[[tweets objectAtIndex:0] identifier] unsignedLongLongValue];
    } else {
        return 0;
    }
}


- (unsigned long long)earliestID {
    if ([tweets count]) {
        return [[[tweets lastObject] identifier] unsignedLongLongValue] - 1;
    } else {
        return 0;
    }
}


- (void)fetchLatestTimeline {
    [self startEnableTimer];
    
    NSString *reqID = nil;
    if (CRTimelineTypeHome == type) {
        reqID = [twitterEngine getFollowedTimelineSinceID:[self latestID] startingAtPage:1 count:DEFAULT_STATUS_FETCH_COUNT];
    } else if (CRTimelineTypeMentions == type) {
        reqID = [twitterEngine getRepliesSinceID:[self latestID] startingAtPage:1 count:DEFAULT_STATUS_FETCH_COUNT];
    } else if (CRTimelineTypeUser == type) {
        reqID = [twitterEngine getUserTimelineFor:displayedUsername sinceID:[self latestID] startingAtPage:1 count:DEFAULT_STATUS_FETCH_COUNT];
    } else {
        NSAssert(0, @"unknown timeline type");
    }
    
    [self setAppend:NO forRequestID:reqID];

    //    NSLog(@"%s: connectionIdentifier = %@", _cmd, reqID);
}


- (void)fetchEarlierTimeline {
    NSString *reqID = nil;
    if (CRTimelineTypeHome == type) {
        reqID = [twitterEngine getFollowedTimelineSinceID:0 withMaximumID:[self earliestID] startingAtPage:1 count:DEFAULT_STATUS_FETCH_COUNT];
    } else if (CRTimelineTypeMentions == type) {
        reqID = [twitterEngine getRepliesSinceID:0 withMaximumID:[self earliestID] startingAtPage:1 count:DEFAULT_STATUS_FETCH_COUNT];
    } else if (CRTimelineTypeUser == type) {
        reqID = [twitterEngine getUserTimelineFor:displayedUsername sinceID:0 withMaximumID:[self earliestID] startingAtPage:1 count:DEFAULT_STATUS_FETCH_COUNT];
    } else {
        NSAssert(0, @"unknown timeline type");
    }
    
    [self setAppend:YES forRequestID:reqID];

    //    NSLog(@"%s: connectionIdentifier = %@", _cmd, reqID);
}


- (void)requestSucceeded:(NSString *)connectionIdentifier {
    [super requestSucceeded:connectionIdentifier];
    //    NSLog(@"Request succeeded for connectionIdentifier = %@", connectionIdentifier);
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
    [super requestFailed:connectionIdentifier withError:error];
    
    [self showRefreshBarButtonItem];
    [self enableFetching];
}


- (void)statusesReceived:(NSArray *)inStatuses forRequest:(NSString *)requestID {
    self.newTweets = [super tweetsFromStatuses:inStatuses];
    NSLog(@"received %d new Tweets", [newTweets count]);
    
    @synchronized(tweets) {
        if (tweets) {
            [tweets addObjectsFromArray:newTweets];
        } else {
            self.tweets = newTweets;
        }
        
        [tweets sortUsingDescriptors:tweetSortDescriptors];
    }
    
    if ([newTweets count]) {
        for (CRTweet *tweet in newTweets) {
            [tweetTable setObject:tweet forKey:[tweet.identifier stringValue]];
        }
        
        [newTweets sortUsingDescriptors:tweetSortDescriptors];
        BOOL append = [self isAppendRequestID:requestID];
        [self prepareAndDisplayTweets:[NSNumber numberWithBool:append]];
    }

    [self updateDisplayedDates];
    [self showRefreshBarButtonItem];
}


- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier {
    //NSLog(@"Got direct messages for %@:\r%@", connectionIdentifier, messages);
}


- (void)connectionFinished:(NSString *)connectionIdentifier {
    //NSLog(@"Connection finished %@", connectionIdentifier);
}


#pragma mark -
#pragma mark MGTwitterEngine

- (void)setUpTwitterEngine {
    fetchingEnabled = YES;
    [super setUpTwitterEngine];
}


#pragma mark -
#pragma mark TDListViewDataSource

- (NSUInteger)numberOfItemsInListView:(TDListView *)lv {
    NSUInteger c = [tweets count];
    return c;
}


- (id)listView:(TDListView *)lv itemAtIndex:(NSUInteger)i {
    CRTweetListItem *item = [listView dequeueReusableItemWithIdentifier:[CRTweetListItem reuseIdentifier]];
    
    if (!item) {
        item = [[[CRTweetListItem alloc] init] autorelease];
        [item.avatarButton setTarget:self];
        [item.avatarButton setAction:@selector(avatarButtonClicked:)];
        [item.usernameButton setTarget:self];
        [item.usernameButton setAction:@selector(usernameButtonClicked:)];
    }
    
    [item.avatarButton setTag:i];
    [item.usernameButton setTag:i];
    item.tweet = [tweets objectAtIndex:i];
    [item setNeedsDisplay:YES];
    
    return item;
}
                           
                           
#pragma mark -
#pragma mark TDListViewDelegate

- (CGFloat)listView:(TDListView *)lv extentForItemAtIndex:(NSUInteger)i {
    NSString *text = [[[tweets objectAtIndex:i] attributedText] string];
    CGFloat width = NSWidth([listView bounds]) - [CRTweetListItem horizontalTextMargins];
    
    CGFloat textHeight = 0;
    if (width > [CRTweetListItem minimumWidthForDrawingText]) {
        NSUInteger opts = NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine;
        NSRect textRect = [text boundingRectWithSize:NSMakeSize(width, MAXFLOAT) options:opts attributes:[CRTweetListItem textAttributes]];
        textHeight = NSHeight(textRect) * [[[CRTweetListItem textAttributes] objectForKey:NSParagraphStyleAttributeName] lineHeightMultiple]; // for some reason lineHeightMultiplier is not factored in by default
    }
    CGFloat height = textHeight + [CRTweetListItem defaultHeight];
    
    CGFloat minHeight = [CRTweetListItem minimumHeight];
    height = (height < minHeight) ? minHeight : height;
    return height;
}


#pragma mark -
#pragma mark WebView

- (void)clearList {
    if ([tweets count]) {
        self.tweets = [NSMutableArray array];
        [listView reloadData];
    }
}


- (void)prepareAndDisplayTweets:(id)appendObj {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(prepareAndDisplayTweets:) withObject:appendObj waitUntilDone:NO];
        return;
    }
    
    //BOOL append = [appendObj boolValue];
    
    id displayUsernames = [[NSUserDefaults standardUserDefaults] objectForKey:kCRTwitterDisplayUsernamesKey];
    
    NSDictionary *vars = [NSDictionary dictionaryWithObjectsAndKeys:
                          newTweets, @"tweets",
                          displayUsernames, @"displayUsernames",
                          //CRDefaultProfileImageURLString(), @"defaultAvatarURLString",
                          nil];
    
    // TODO
    vars;
}


- (void)updateDisplayedDates {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updateDisplayedDates) withObject:nil waitUntilDone:NO];
        return;
    }

    for (CRTweet *tweet in tweets) {
        [tweet updateAgo];
    }

    [listView reloadData];
}


//#pragma mark -
//#pragma mark WebFrameLoadDelegate
//
//- (void)webView:(WebView *)wv didFinishLoadForFrame:(WebFrame *)frame {
//    if (frame != [webView mainFrame]) return;
//    
//    [self showRefreshBarButtonItem];
//    if (visible) {
//        [self beginFetchLoop];
//    }
//}


#pragma mark -
#pragma mark WebScripting

//#pragma mark -
//#pragma mark WebUIDelegate
//
//- (void)webView:(WebView *)wv mouseDidMoveOverElement:(NSDictionary *)d modifierFlags:(NSUInteger)modifierFlags {
//    if (wv != webView) return;    
//    
//    NSString *titleAttr = [d objectForKey:WebElementLinkTitleKey];
//    if ([titleAttr isEqualToString:@"nostatus"]) {
//        return;
//    }
//    
//    NSURL *URL = [d objectForKey:WebElementLinkURLKey];
//    NSString *statusText = nil;
//    
//    if (URL) {
//        NSString *URLString = CRStringByTrimmingCruzPrefixFromURL(URL);
//        
//        BOOL tabsEnabled = [[CRTwitterPlugIn instance] tabbedBrowsingEnabled];
//        NSString *fmt = nil;
//        if (tabsEnabled) {
//            fmt = NSLocalizedString(@"Open \"%@\" in a new tab", @"");
//        } else {
//            fmt = NSLocalizedString(@"Open \"%@\" in a new window", @"");
//        }
//                
//        statusText = [NSString stringWithFormat:fmt, URLString];
//    } else {
//        statusText = @"";
//    }
//    
//    [[CRTwitterPlugIn instance] showStatusText:statusText];
//}
//
//
//- (NSArray *)webView:(WebView *)wv contextMenuItemsForElement:(NSDictionary *)d defaultMenuItems:(NSArray *)defaultMenuItems {
//    NSURL *URL = [d objectForKey:WebElementLinkURLKey];
//    if (!URL) return nil;
//
//    self.lastClickedElementInfo = d;
//    
//    NSMutableArray *items = [NSMutableArray arrayWithCapacity:3];
//    
//    NSMenuItem *item = nil;
//
//    if ([[CRTwitterPlugIn instance] tabbedBrowsingEnabled]) {
//        item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Link in New Tab ", @"") 
//                                           action:@selector(openLinkInNewTabFromMenu:)
//                                    keyEquivalent:@""] autorelease];
//        [item setTarget:self];
//        [items addObject:item];
//    }
//
//    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Link in New Window ", @"") 
//                                       action:@selector(openLinkInNewWindowFromMenu:)
//                                keyEquivalent:@""] autorelease];
//    [item setTarget:self];
//    [items addObject:item];
//    
//    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Link", @"") 
//                                       action:@selector(copyLinkFromMenu:)
//                                keyEquivalent:@""] autorelease];
//    [item setTarget:self];
//    [items addObject:item];
//    
//    return items;
//}
//
//
//- (void)webView:(WebView *)wv willPerformDragSourceAction:(WebDragSourceAction)action fromPoint:(NSPoint)p withPasteboard:(NSPasteboard *)pboard {
//    if (WebDragSourceActionLink == action) {
//        NSArray *oldURLs = [WebURLsWithTitles URLsFromPasteboard:pboard];
//        NSArray *titles = [WebURLsWithTitles titlesFromPasteboard:pboard];
//        NSMutableArray *newURLs = [NSMutableArray arrayWithCapacity:[oldURLs count]];
//        
//        // declare types
//        NSArray *types = [NSArray arrayWithObjects:WebURLsWithTitlesPboardType, NSURLPboardType, NSStringPboardType, nil];
//        [pboard declareTypes:types owner:nil];
//
//        // write data
//        for (NSURL *oldURL in oldURLs) {
//            NSURL *newURL = [NSURL URLWithString:CRStringByTrimmingCruzPrefixFromURL(oldURL)];
//            [newURLs addObject:newURL];
//            [newURL writeToPasteboard:pboard];
//            [pboard setString:[newURL absoluteString] forType:NSStringPboardType];
//        }
//        
//        [WebURLsWithTitles writeURLs:newURLs
//                           andTitles:titles
//                        toPasteboard:pboard];
//    }
//}
//

- (IBAction)openLinkInNewTabFromMenu:(id)sender {
    [self openLinkInNewTab:YES];
}


- (IBAction)openLinkInNewWindowFromMenu:(id)sender {
    [self openLinkInNewTab:NO];
}   


- (void)openLinkInNewTab:(BOOL)inTab {
//    NSURL *URL = [lastClickedElementInfo objectForKey:WebElementLinkURLKey];
//    [self openURL:URL inNewTab:inTab];
//    self.lastClickedElementInfo = nil;
}


- (void)pushThread:(NSString *)statusID {
    CRThreadViewController *vc = [[[CRThreadViewController alloc] init] autorelease];
    vc.tweet = [tweetTable objectForKey:statusID];
    [self.navigationController pushViewController:vc animated:NO];
}


- (IBAction)copyLinkFromMenu:(id)sender {
//    NSString *aTitle = [lastClickedElementInfo objectForKey:WebElementLinkTitleKey];
//    NSURL *URL = [lastClickedElementInfo objectForKey:WebElementLinkURLKey];
//    NSString *URLString = CRStringByTrimmingCruzPrefixFromURL(URL);
//    URL = [NSURL URLWithString:URLString];
//
//    // get pboard
//    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
//
//    // declare types
//    NSArray *types = [NSArray arrayWithObjects:WebURLsWithTitlesPboardType, NSURLPboardType, NSStringPboardType, nil];
//    [pboard declareTypes:types owner:nil];
//
//    // write data
//    [URL writeToPasteboard:pboard];
//    [pboard setString:[URL absoluteString] forType:NSStringPboardType];
//    
//    if (URL && aTitle) {
//        [WebURLsWithTitles writeURLs:[NSArray arrayWithObject:URL]
//                           andTitles:[NSArray arrayWithObject:aTitle]
//                        toPasteboard:pboard];
//    }
//    
//    self.lastClickedElementInfo = nil;
}    

@synthesize displayedUsername;
@synthesize defaultProfileImageURL;
@synthesize tweets;
@synthesize newTweets;
@synthesize tweetTable;
@synthesize tweetSortDescriptors;
@synthesize fetchTimer;
@synthesize enableTimer;
@synthesize datesTimer;
@synthesize appendTable;
@end
