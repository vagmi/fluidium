//
//  CRBaseViewController.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/8/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <UMEKit/UMEKit.h>
#import <TDAppKit/TDListView.h>
#import "MGTwitterEngine.h"

@class DOMHTMLElement;

@interface CRBaseViewController : UMEViewController <MGTwitterEngineDelegate, TDListViewDataSource, TDListViewDelegate> {
    TDListView *listView;

    MGTwitterEngine *twitterEngine;
}

- (void)setUpTwitterEngine;

- (NSMutableArray *)processStatuses:(NSArray *)inStatuses;


- (void)pushTimelineFor:(NSString *)username;
- (void)handleUsernameClicked:(NSString *)username;
- (void)openUserPageInNewTabOrWindow:(NSString *)username;
- (void)openURLInNewTabOrWindow:(NSString *)URLString;
- (void)openURLString:(NSString *)URLString inNewTab:(BOOL)inTab;
- (void)openURL:(NSURL *)URLString inNewTab:(BOOL)inTab;

@property (nonatomic, retain) IBOutlet TDListView *listView;
@property (nonatomic, retain) MGTwitterEngine *twitterEngine;
@end
