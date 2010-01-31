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

#import <UMEKit/UMEKit.h>
#import <TDAppKit/TDListView.h>
#import "MGTwitterEngine.h"

@class DOMHTMLElement;

@interface CRBaseViewController : UMEViewController <MGTwitterEngineDelegate, TDListViewDataSource, TDListViewDelegate> {
    TDListView *listView;

    MGTwitterEngine *twitterEngine;
}

- (void)setUpTwitterEngine;

- (NSMutableArray *)tweetsFromStatuses:(NSArray *)inStatuses;


- (void)pushTimelineFor:(NSString *)username;
- (void)handleUsernameClicked:(NSString *)username;
- (void)openUserPageInNewTabOrWindow:(NSString *)username;
- (void)openURLInNewTabOrWindow:(NSString *)URLString;
- (void)openURLString:(NSString *)URLString inNewTab:(BOOL)inTab;
- (void)openURL:(NSURL *)URLString inNewTab:(BOOL)inTab;

@property (nonatomic, retain) IBOutlet TDListView *listView;
@property (nonatomic, retain) MGTwitterEngine *twitterEngine;
@end
