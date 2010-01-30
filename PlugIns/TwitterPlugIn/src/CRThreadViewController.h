//
//  CRThreadViewController.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/8/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRBaseViewController.h"

@interface CRThreadViewController : CRBaseViewController {
    NSDictionary *tweet;
    NSString *usernameA;
    NSString *usernameB;
}

@property (nonatomic, retain) NSDictionary *tweet;
@property (nonatomic, copy) NSString *usernameA;
@property (nonatomic, copy) NSString *usernameB;
@end
