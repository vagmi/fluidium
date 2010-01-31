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

    NSMutableArray *newTweets;
    NSMutableDictionary *tweetTable;
    NSArray *tweetSortDescriptors;
    NSTimer *fetchTimer;
    NSTimer *enableTimer;
    NSTimer *datesTimer;
    BOOL fetchingEnabled;
    
    BOOL visible;
}

- (id)initWithType:(CRTimelineType)t;

- (IBAction)showAccountsPopUp:(id)sender;
- (IBAction)accountSelected:(id)sender;
- (IBAction)fetchLatestStatuses:(id)sender;
- (IBAction)fetchEarlierStatuses:(id)sender;
- (IBAction)showAccountsPopUp:(id)sender;
- (IBAction)pop:(id)sender;

@property (nonatomic, copy) NSString *displayedUsername;
@end
