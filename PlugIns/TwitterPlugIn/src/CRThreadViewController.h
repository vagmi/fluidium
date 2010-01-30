//
//  CRThreadViewController.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/8/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRBaseViewController.h"

@class CRTweet;

@interface CRThreadViewController : CRBaseViewController {
    CRTweet *tweet;
    NSString *usernameA;
    NSString *usernameB;
}

@property (nonatomic, retain) CRTweet *tweet;
@property (nonatomic, copy) NSString *usernameA;
@property (nonatomic, copy) NSString *usernameB;
@end
