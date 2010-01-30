//
//  CRTimelineViewController.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 10/16/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRBaseViewController.h"

typedef enum {
    CRTimelineTypeHome = 0,
    CRTimelineTypeMentions = 1,
    CRTimelineTypeUser = 2,
} CRTimelineType;

@interface CRTimelineViewController : CRBaseViewController {    
    CRTimelineType type;

    NSString *displayedUsername;
    NSURL *defaultProfileImageURL;
    NSDictionary *lastClickedElementInfo;

    NSMutableArray *tweets;
    NSMutableArray *newTweets;
    NSMutableDictionary *tweetTable;
    NSArray *tweetSortDescriptors;
    NSTimer *fetchTimer;
    NSTimer *enableTimer;
    NSTimer *datesTimer;
    BOOL fetchingEnabled;
    
    BOOL visible;
    
    NSMutableDictionary *appendTable;
}

- (id)initWithType:(CRTimelineType)t;

- (IBAction)showAccountsPopUp:(id)sender;
- (IBAction)accountSelected:(id)sender;
- (IBAction)fetchLatestStatuses:(id)sender;
- (IBAction)fetchEarlierStatuses:(id)sender;
- (IBAction)showAccountsPopUp:(id)sender;
- (IBAction)pop:(id)sender;

- (IBAction)usernameButtonClicked:(id)sender;

@property (nonatomic, copy) NSString *displayedUsername;
@end
